# Copyright (c) 2016-2025, Claudio Bustos Navarrete
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

# Several utilities to work with PubMed API
class RisReader
  attr_reader :records
  def initialize(string)
    @string=string

    @errors=[]
    if @string.length>3 and @string.bytes[0..2]==[239,187,191]
      @string=@string[1..-1]
    end
    @records=[]
  end


  def process
    current_record={}
    ris_pattern = /^(?<tag>[A-Z][A-Z0-9])\s{0,2}-\s{0,2}(?<value>.*)$/

    # WoS RIS is savage. Both \r and \n are used.
    # No point in be civilized
    lines=@string.split(/[\r\n]+/)
    i=0
    @string.each_line do |line|

      line.strip!
      next if line==""
      #puts line.inspect
      # Match the pattern against the RIS line
      match = line.match(ris_pattern)
      # Access the tag and value using named capture groups
      if match
        tag = match[:tag]
        value = match[:value].strip
        if tag=="ER"
          @records.push(current_record.dup)
          current_record={}
        else
          if current_record.has_key? tag
            if current_record[tag].is_a? Array
              current_record[tag].push(value)
            else
              current_record[tag]=[current_record[tag], value]
            end
          else
            current_record[tag]=value
          end
        end
      elsif line=~/(^.+):(.+)$/
        current_record[$1]=$2.strip
      else
        #puts "****"
        #hex_codes = line.bytes.map { |b| sprintf("%02X", b) }.join
        #puts hex_codes
        #puts  match.inspect
        #puts line.inspect
        #raise "ERROR"
        @errors.push({line_number:i, text:line})
      end
      i+=1
    end
  end
end