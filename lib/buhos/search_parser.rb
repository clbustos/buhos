# Copyright (c) 2016-2022, Claudio Bustos Navarrete
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require 'treetop'
require 'sequel'
module SearchGrammar

  module FilterGroup
    def to_array
      self.elements.map {|x| x.to_array }
    end
  end

  module Boolean
    def to_array
      e1=(self.elements[0].respond_to?(:to_array)) ? self.elements[0].to_array : self.elements[0].text_value
      e2=(self.elements[2].respond_to?(:to_array)) ? self.elements[2].to_array : self.elements[2].text_value

      [:boolean, self.elements[1].text_value.to_sym, e1,e2]
      #BooleanElement.new(self.elements[1].text_value, e1,e2)
    end
  end

  module Filter
    def to_array
      el=self.elements
      field=el.shift
      [:filter, field.text_value.to_sym, el.map {|x| x.to_array }]

      #self.elements.map {|x| x.to_array}
    end
  end

  module Identifier
    def to_array
      [:string, self.text_value]
    end
  end


  module String
    def to_array
      [:string_q, text_value]
    end
  end


  module Required
    def to_array
      [:required, self.text_value]
    end
  end

  module Body
    def to_array
      self.elements.map {|x| (x.respond_to?(:to_array)) ? x.to_array : x.text_value}
    end
  end

  module Expression
    def to_array
      self.elements.delete_if{|v|  v.text_value=="(" or v.text_value==")" }.map {|x| (x.respond_to?(:to_array)) ? x.to_array : x.text_value}
    end
  end

  module Space
    def to_array
      :space
    end
  end
end

#

module Buhos

  class SearchParser
    attr :tree
    attr :tree_processed
    class ParsingError < StandardError

    end
    def initialize
      Treetop.load "#{File.dirname(__FILE__)}/search_grammar.treetop"
      @parser=::SearchGrammarParser.new
    end

    def parse(data)
      #$log.info("PARSING:#{data}")
      @tree=@parser.parse(data)
      if @tree.nil?
        raise ParsingError, "Parse error at offset: #{@parser.index}"
      end


      @tree=clean_tree(@tree)

      @tree_processed=@tree.to_array
    end

    def clean_tree(root_node)
      return if(root_node.elements.nil?)
      root_node.elements.delete_if{|node| node.text_value=='' or node.text_value=~/^\s+$/}
      root_node.elements.each {|node| self.clean_tree(node) }
      root_node
    end

    def to_sql_elements(field,e)
      #p e
      if e.is_a? Array
        if e[0]==:string
          "INSTR(LOWER(#{field}), '#{::Sequel.lit e[1].downcase}')>0 "
        elsif e[0]==:string_q
          "INSTR(LOWER(#{field}), '#{::Sequel.lit(e[1].gsub('"',"").downcase)}')>0 "
        elsif e[0]==:boolean
          "(#{to_sql_elements(field,e[2])} #{e[1]} #{to_sql_elements(field,e[3])})"
        else
          if e.length==1
            to_sql_elements(field,e[0])
          else
            e.map {|v| "(#{to_sql_elements(field,v)})" }.join" AND "
          end
        end
      else
        "  "
      end
    end
    def to_sql(or_union:false)
      raise "First parse data" unless @tree
      @tree_processed.map { |f0|
        filter=f0.dup
        next if filter[0]!= :filter
        filter.shift
        field=filter.shift
        elements=filter
        to_sql_elements(field, elements)
      }.join( or_union ? " OR ": " AND ")
    end


  end
end