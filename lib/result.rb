class Result
  attr_reader :events
  def initialize()
    @status=:ok
    @events=[]
  end
  def info(message)
    @events.push({type: :info, message: message })
  end
  def success(message)
    @events.push({type: :success, message: message })
  end
  def error(message)
    @events.push({type: :error, message: message })
  end
  def warning(message)
    @events.push({type: :warning, message: message })
  end
  def success?
    !@events.any? {|v| v[:type]==:error}
  end
  def message
    @events.map {|v| "#{v[:type]}: #{v[:message]}"}.join("\n")
  end
  # Permite agregar los eventos de otro resultado
  def add_result(new_result)
    @events=@events+new_result.events
  end
end