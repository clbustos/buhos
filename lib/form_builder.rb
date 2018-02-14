require_relative "html_helpers"
# Create custom forms for complete text data extraction phase
#
class FormBuilder
  def initialize(sr, cd,user)
    @sr=sr
    @cd=cd
    @user=user
  end
  def each_field
    Rs_Campo.where(:revision_sistematica_id=>@sr[:id]).order(:orden).each do |field|
      yield Field.new(field, @sr,@cd, @user)
    end
  end

  class Field
    include ::HTMLHelpers
    def initialize(rs_campo, sr, cd, user)
      @rs_campo=rs_campo
      @sr=sr
      @cd=cd
      @user=user
      @row=@sr.analisis_cd_user_row(@cd,@user)
      @value=@row[@rs_campo.nombre.to_sym]
    end
    def description
      @rs_campo.descripcion
    end
    def html
      case @rs_campo.tipo
        when 'textarea'
          textarea_html
        when 'text'
          text_html
        else
          raise("Not implemented")
      end
    end
    def textarea_html
      a_textarea_editable(@rs_campo.nombre, "form-cd-extraction", "/revision/#{@sr[:id]}/extract_information/cd/#{@cd[:id]}/user/#{@user[:id]}/update_field", @value)
    end
    def text_html
      a_editable(@rs_campo.nombre, "form-cd-extraction", "/revision/#{@sr[:id]}/extract_information/cd/#{@cd[:id]}/user/#{@user[:id]}/update_field", @value)
    end
  end
end