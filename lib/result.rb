# Retrieve messages for complex process
# #events store each state as hash, with keys :message and :type
#
# Example
#     result=Result.new
#     result.info("Something happened")
#     result.success? # returns true
#     result.error("Something bad happened")
#     result.success? # returns false
#     result.message # return 'info: Something happened\nerror:Something bad happened'
class Result
  attr_reader :events
  def initialize()
    #@status=:ok
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