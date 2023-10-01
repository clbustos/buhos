# Copyright (c) 2023, Claudio Bustos Navarrete
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

class OutgoingEmail
  def initialize
    @smtp_server=ENV['SMTP_SERVER']
    @smtp_user=ENV['SMTP_USER']
    @smtp_password=ENV['SMTP_PASSWORD']
    @smtp_security=ENV['SMTP_SECURITY']
    @smtp_port=ENV['SMTP_PORT']
    @result=Result.new
  end

  def send_email(email_to,subject_message,message)
    require 'mail'

    smtp={address: @smtp_server,
          port: @smtp_port,
          :user_name => @smtp_user,
          :password => @smtp_password,
          :enable_starttls_auto => @smtp_security=='STARTTLS'}
    #$log.info(smtp)
    if ENV['RACK_ENV']=='test'
      Mail.defaults do
        delivery_method :test
      end
    else
      if @smtp_server.nil?
        raise "No SMTP server defined"
      end

      Mail.defaults do
        delivery_method :smtp, smtp
      end

    end



    begin
      mail = Mail.new do
        to email_to
        subject subject_message
        body message
      end
      mail.from=@smtp_user
      mail.header["List-Unsubscribe"]="unsuscribe@investigarenpsicologia.cl"
      mail.to_s =~ /Message\-ID: <([\d\w_]+@.+.mail)/
      email_message_id=$1
      #$log.info(mail.to_s)
      mail.deliver
      $log.info "Se envió el correo #{email_message_id} a #{email_to} por cuenta #{@smtp_user} en  #{DateTime.now}"
      #message="Se envió el correo #{email_message_id} a #{correo}"
      #status="SEND_OK"
    rescue Exception => e
      status="SEND_ERROR"
      $log.error "No se pudo enviar el correo #{e.message}:#{email_to}"
      return false
    end
    return true
  end


end