require_relative "html_helpers"
require_relative "sinatra_helpers"

# Create custom forms for complete text data extraction phase
#
class FormBuilder
  def initialize(sr, cd,user)
    @sr=sr
    @cd=cd
    @user=user
    @javascript=[]
  end
  def each_field
    SrField.where(:systematic_review_id=>@sr[:id]).order(:order).each do |field|
      yield Field.new(field, @sr,@cd, @user,self)
    end
  end
  def add_javascript(js)
    @javascript.push(js)
  end
  def javascript
    return "" unless @javascript.length>0
    "<script type='text/javascript'>
    #{@javascript.join("\n")}
    </script>"
  end

  class Field
    include ::HTMLHelpers
    include ::Sinatra::Xeditable_Checkbox::Helpers
    include ::Sinatra::Xeditable_Select::Helpers

    def initialize(rs_campo, sr, cd, user,form_builder)
      @rs_campo=rs_campo
      @form_builder=form_builder
      @sr=sr
      @cd=cd
      @user=user
      @row=@sr.analysis_cd_user_row(@cd,@user)
      @value=@row[@rs_campo.name.to_sym]

    end
    def add_javascript_to_fb(js)
      @form_builder.add_javascript(js)
    end
    def description
      @rs_campo.description
    end
    def html
      case @rs_campo.type
        when 'textarea'
          textarea_html
        when 'text'
          text_html
        when 'select'
          select_html
        when 'multiple'
          checkbox_html
        else
          raise 'not implemented'
      end
    end
    def url_update
      "/review/#{@sr[:id]}/extract_information/cd/#{@cd[:id]}/user/#{@user[:id]}/update_field"
    end
    def textarea_html
      a_textarea_editable(@rs_campo.name, "form-cd-extraction",url_update , @value)
    end
    def text_html
      a_editable(@rs_campo.name, "form-cd-extraction", url_update, @value)
    end
    def select_html
      xselect=get_xeditable_select({nil=>"-- #{I18n::t(:empty)} -- "}.merge(@rs_campo.options_as_hash),  url_update, "xcheckbox_form_#{@rs_campo.name}")
      add_javascript_to_fb(xselect.javascript)
      xselect.html(@rs_campo.name, @value)
    end
    def checkbox_html
      value_as_array=@value.nil? ? [] : @value.split(",")
      xcheckbox=get_xeditable_checkbox(@rs_campo.options_as_hash,  url_update, "xselect_form_#{@rs_campo.name}")
      add_javascript_to_fb(xcheckbox.javascript)
      xcheckbox.html(@rs_campo.name, value_as_array)
    end
  end
end