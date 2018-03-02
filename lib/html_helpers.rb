
module HTMLHelpers
  def a_tag(href,text)
    "<a href='#{href}'>#{text}</a>"
  end
  def a_tag_badge(href,text)
    "<a href='#{href}'><span class='badge'>#{text}</span></a>"
  end
  def lf_to_br(t)
    t.nil? ? "" : t.split("\n").join("<br/>")
  end

  def url(ruta)
    if @mobile
      "/mob#{ruta}"
    else
      ruta
    end
  end

  def put_editable(b,&block)
    params=b.params
    value=params['value'].chomp
    return 505 if value==""
    id=params['pk']
    block.call(id, value)
    return 200
  end

  def class_bootstrap_contextual(cond, prefix, clase, clase_no="default")
    cond ? "#{prefix}-#{clase}" : "#{prefix}-#{clase_no}"
  end
  def bool_class(x, yes,no,nil_class)
    if x.nil?
      nil_class
    else
      x ? yes : no
    end
  end
  def decision_class_bootstrap(type, prefix)
    suffix=case type
             when nil
               "default"
             when "yes"
               "success"
             when "no"
               "danger"
             when "undecided"
               "warning"
           end
    prefix.nil? ? suffix  : "#{prefix}-#{suffix}"
  end


  def a_textarea_editable(id, prefix, data_url, v, default_value="--")
    url_s=url(data_url)

    "<a class='textarea_editable' data-pk='#{id}' data-url='#{url_s}' href='#' id='#{prefix}-#{id}' data-placeholder='#{default_value}'>#{v}</a>"
  end

  # Generates a text input for x-editable.
  # @param id Primary key of object to edit
  # @param prefix the id for the element is 'prefix'-'id'
  # @param data_url URL for edition of text
  # @param v Current value
  # @param placeholder Placeholder for field before entering data
  # @example a_editable(user.id, 'user-name', 'user/edit/name', user.name, t(:user_name))
  def a_editable(id, prefix, data_url, v,placeholder='--')
    url_s=url(data_url)
    "<a class='name_editable' data-pk='#{id}' data-url='#{url_s}' href='#' id='#{prefix}-#{id}' data-placeholder='#{placeholder}'>#{v}</a>"
  end

  # Check if we have permission to do an edit
  def permission_a_editable(have_permit, id, prefix, data_url, v,placeholder)
    if have_permit
      a_editable(id,prefix,data_url,v,placeholder)
    else
      v
    end
  end
end