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
module Sinatra
  module I18n
    module Helpers
      def get_lang(http_lang)
        accepted=["en","es","pl"]
        unless http_lang.nil?
          langs=http_lang.split(",").map {|v|
            v.split(";")[0].split("-")[0]
          }.each  {|l|
            return l if accepted.include? l
          }
        end
        "en"
      end

      # Just a wrapper for I18n::t method
      def t(...)
        ::I18n::t(...)
      end

      def t_taxonomy_group(term)
        ::I18n::t("sr_taxonomy.#{term}")
      end
      def t_taxonomy_category(terms)
        $log.info(terms)
        if terms.is_a? String
          ::I18n::t("sr_taxonomy_category.#{terms}")
        elsif is_a? Array
          terms.map {|term| ::I18n::t("sr_taxonomy_category.#{term}")}.join("," )
        end
      end
      def t_yes_no_nil(x)
        if x.nil?
          ::I18n::t(:Not_defined)
        else
          x ? ::I18n::t(:Yes) : ::I18n::t(:No)
        end
      end

      # Put the term on strong tag, double colon, and later the value
      # @param term Term to be i18n and marked with strong tag
      # @param value Value to be presented, without changes
      def t_desc_value(term, value)
        "<strong>#{::I18n::t(term)}:</strong>&nbsp;#{value}"
      end

      def t_generic_title(object_name, secondary, translate_secondary=true)
        secondary_traslation= translate_secondary ? ::I18n::t(secondary) : secondary
        @title="#{secondary_traslation} - #{object_name}"
        "<h2>#{object_name}</h2><h3>#{secondary_traslation}</h3>"
      end

      # Set title for systematic review pages
      def t_systematic_review_title(sr_name, secondary, translate_secondary=true)
        sr_title = ::I18n::t(:systematic_review_title, sr_name: sr_name)
        t_generic_title(sr_title, secondary, translate_secondary)
      end

      # Set title for canonical document pages
      def t_canonical_document_title(cd_title, secondary, translate_secondary=true)
        cd_title = ::I18n::t(:canonical_document_title, cd_title: cd_title)
        t_generic_title(cd_title, secondary, translate_secondary)
      end

      # Set title for searches pages
      def t_search_title(sr_name, search_name, secondary)
        @title="#{::I18n::t(secondary)} - #{::I18n::t(:search_title, search_name:search_name)} - #{::I18n::t(:systematic_review_title_abbrev, sr_name:sr_name)}"
        "<h2>#{::I18n::t(:search_title, search_name: search_name)} - #{::I18n::t(:systematic_review_title_abbrev, sr_name:sr_name)}</h2><h3>#{::I18n::t(secondary)}</h3>"
      end
      def available_locales
        [:es,:en,:pl]
      end
      def available_locales_hash
        available_locales.inject({}) {|ac,v|
          ac[v] = ::I18n.t("locale.#{v}");ac
        }

      end
    end

    def self.registered(app)
      app.helpers I18n::Helpers

      app.before do
        #$log.info("Sesion es:#{session['language']}")
        if session['language'].nil?
          language=get_lang(request.env['HTTP_ACCEPT_LANGUAGE'])
          #$log.info("Desde HTTP:#{language}")
          language='en' unless ['en','es','pl'].include? language
          ::I18n.locale = language
        else
          ::I18n.locale = session['language'].to_sym
        end
      end


      #$log.info(app.root)
      unless defined?(app.locales)
        app.set :locales, File.join(app.root, 'config','locales', '*.yml')
      end
      ::I18n.load_path+=Dir[app.locales]
      ::I18n.config.available_locales = [:es,:en,:pl]
      ::I18n.default_locale=:en
      #::I18n.backend.load_translations(app.locales)
    end
  end
  register I18n
end