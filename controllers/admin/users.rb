# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2025, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information


# @!group users

get '/admin/users_batch_edition' do
  halt_unless_auth('user_admin')
  haml "users/batch_edition".to_sym, escape_html: false
end


get '/admin/users_batch_edition/excel_export' do
  require 'caxlsx'

  halt_unless_auth('user_admin')
  package = Axlsx::Package.new
  wb = package.workbook
  blue_cell = wb.styles.add_style  :fg_color => "0000FF", :sz => 14, :alignment => { :horizontal=> :center }
  wrap_text = wb.styles.add_style alignment: { wrap_text: true }
  little_text = wb.styles.add_style
  users=User.where(Sequel.lit("role_id!='administrator'"))
  institutions=Institution.to_hash(:id,:name)
  wb.add_worksheet(:name => t(:Users)) do |sheet|
    header=["id","active","email","institution","language","login","name","password","role_id"]
    sheet.add_row header, :style=> [blue_cell]*9
    users.each do |user|
      row=[user[:id], user[:active] ? 1:0, user[:email], institutions.fetch(user[:institution_id], nil), user[:language],
           user[:login], user[:name], nil, user[:role_id]]
      sheet.add_row row
    end
  end

  headers 'Content-Type' => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  headers 'Content-Disposition' => "attachment; filename=users.xlsx"
  package.to_stream
end


post '/admin/users_batch_edition/excel_import' do
  require 'simple_xlsx_reader'
  SimpleXlsxReader.configuration.auto_slurp = true
  archivo=params.delete("file")

  doc = SimpleXlsxReader.open(archivo["tempfile"])
  sheet=doc.sheets.first
  header=sheet.headers
  id_index       = header.find_index("id")
  id_active      = header.find_index("active")
  id_email       = header.find_index("email")
  id_institution = header.find_index("institution")
  id_language    = header.find_index("language")
  id_login       = header.find_index("login")
  id_name        = header.find_index("name")
  id_password    = header.find_index("password")
  id_role        = header.find_index("role_id")
  
  lista_excel={"id"=> id_index,"active"=> id_active, "email"=>id_email, 
  "institution"=>id_institution, "language"=>id_language,
  "login"=>id_login, "name"=>id_name, "password"=>id_password,
  "role_id"=>id_role}
  result=Result.new
  missing_fields=lista_excel.find_all{|field,value| value.nil?}.map{|x| x[0]}
  if missing_fields.length >0
    result.error("Missing fields:#{missing_fields.join(', ')}")
    add_result(result)
    redirect url("/admin/users_batch_edition")
  end
  
  

  institutions_names=Institution.to_hash(:name, :id)
  users_assignation={}
  header.each_index { |i|
    if header[i]=~/\[(\d+)\].+/
      users_assignation[i]=$1
    end
  }
  number_of_actions=0
  $db.transaction(:rollback => :reraise) do
    sheet.data.each do |row|
      user_id=row[id_index]
      active=row[id_active].to_i == 1
      email=row[id_email]
      login=row[id_login]
      name=row[id_name]

      next if login.nil? or name.nil?

      institution=row[id_institution].nil? ? "**NO INSTITUTION**": row[id_institution].strip
      language=row[id_language]
      password=row[id_password]
      role_id=row[id_role]

      institution_id=institutions_names[institution] || Institution.find_or_create(name:institution)[:id]

        # Login and name should be the same. If not, ok
      if user_id.nil?
        # Create user, if login and e-mail doesn't exists

        if User.where {Sequel.or(email:email, login:login, name:name)}.count>0
          result.error("User already exists:#{login}, #{name}, #{email}")
        else
          user_o=User.create(active:active, email:email, institution_id:institution_id,
                      language:language, login:login, name:name, password:Digest::SHA1.hexdigest(password),
                             role_id:role_id)
          result.success("User add: #{name}")
        end
      else
        user_o=User[id:user_id]
        if user_o
          to_update={active:active, email:email, institution_id:institution_id,
                     language:language, login:login, name:name,
                     role_id:role_id }
          if !password.nil? and password.strip!=""
            to_update[:password]=Digest::SHA1.hexdigest(password)
          end
          to_update_2=to_update.inject({}) {|ac,v|
            if v[1]!=user_o[v[0]]
              ac[v[0].to_sym]=v[1]
            end
            ac
          }
          #$log.info(to_update_2)
          if to_update_2.length>0
            $log.info(to_update_2)
            user_o.update(values=to_update_2)
            result.success("User update: #{user_id}")
            number_of_actions+=1
          end
        else
          result.error("User doesn't exists:#{user_id}")
        end
      end

    end
  end
  if number_of_actions==0
    result.info(::I18n::t(:Nothing_to_update))
  end
  add_result(result)
  redirect url("/admin/users_batch_edition")

end

# Get list of users
get '/admin/users/?' do
  halt_unless_auth('user_admin')
  @usr_bus=params[:users_search]
  if(@usr_bus.nil? or @usr_bus=="")
    @users=User.all
  else
    @users=User.filter(Sequel.ilike(:name, "%#{@usr_bus}%")).order(:name)
  end

  @have_permit_password = auth_to("user_admin")

  #log.info(@personas.all)
  @roles=Role.order()
  haml :users, escape_html: false
end



# Update information for users
post '/admin/users/update' do
  halt_unless_auth('user_admin')
  if params['user'].nil?
    add_message(::I18n.t(:No_users_selected), :error)
    redirect back
  end
  users=params['user']
  if params['action']=='inactive'
    User.where(:id => users).update(:active=>false)
    add_message(::I18n.t("users_admin.action_inactive", ids: users.join(",")))
  elsif params['action']=='active'
    User.where(:id => users).update(:active=>true)
    add_message(::I18n.t("users_admin.action_active", ids: users.join(",")))
  elsif params['action']=='delete'
    @users_id=users
    @users=User.where(:id=>@users_id)
    if @users_id.map(&:to_i).include? session['user_id']
      add_message(::I18n.t("users_admin.cant_delete_itself"))
      redirect back
    else
      return haml "users/delete_confirm".to_sym, escape_html: false
    end
  elsif params['action']=='edit'
    @users_id=users
    @users=User.where(:id=>@users_id)
    return haml "users/multiple_edit".to_sym, escape_html: false
  end
  redirect back
end


post '/admin/users/delete' do
  if params['action']=='delete'
    users=User.where(:id=>params['users'].split(","))

    if !users
      add_message(::I18n.t("users_admin.no_valid_user_selected"), :error)
    else
      $db.transaction do
        User.where(:id=>params['users'].split(",")).delete
      end
      add_message(::I18n.t("users_admin.action_delete", ids: params['users']))
    end
  end
  redirect url('admin/users')
end

post '/admin/users/update_edit' do
  user_info=params['user']
  if !user_info
    add_message(::I18n.t("users_admin.no_valid_user_selected"), :error)
    redirect url("admin/users")
  else
    result=Result.new
    user_info.each do |user_id, user_info|
      begin
        if user_info[:name].strip==""
          result.error(::I18n.t("users_admin.user_should_have_a_name", id: user_id))
        elsif user_info[:login].strip==""
          result.error(::I18n.t("users_admin.user_should_have_a_login", id: user_id))
        else
          $db.transaction do
            User[user_id].update(name:user_info[:name],
                                 login:user_info[:login],
                                 active: user_info[:active].to_i==1,
                                 role_id: user_info[:role_id],
                                 email: user_info[:email],
                                 institution_id:user_info[:institution_id],
                                 language: user_info[:language])
            result.success(::I18n.t("users_admin.update_was_successful", id: user_id))
            end
        end

        rescue Exception => e
          result.error(::I18n.t("users_admin.update_failed", id: user_id, message:e.message))
        end
    end
    add_result(result)
  end
  if result.success?
    redirect url("admin/users")
  else
    @users_id=user_info.keys
    @users=User.where(:id=>@users_id)
    return haml "users/multiple_edit".to_sym, escape_html: false
  end
end






# @!endgroup
