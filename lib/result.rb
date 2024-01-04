# Copyright (c) 2016-2024, Claudio Bustos Navarrete
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
  # Number of events
  def count
    @events.count
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