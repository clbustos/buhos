class Message < Sequel::Model
  def user_name
    User[self[:user_from]].name
  end
  def replies
    Message.where(:reply_to=>self[:id])
  end
end


class MessageSr < Sequel::Model
  def user_name

    User[self[:user_from]]&.name
  end
  # Messages que son respuesta a este mensaje
  def replies
    MessageSr.where(:reply_to=>self[:id])
  end

end

class MessageSrSeen < Sequel::Model

end
