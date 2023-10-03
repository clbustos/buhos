# Copyright (c) 2016-2023, Claudio Bustos Navarrete
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

# encoding: UTF-8


class Buhos::Configuration < Sequel::Model
  def self.set(id,valor)
    conf=Buhos::Configuration[id]
    if conf.nil?
      Buhos::Configuration.insert(:id=>id,:valor=>valor)
    else
      Buhos::Configuration[id].update(:valor=>valor)
    end
  end
  def self.get(id)
    conf=Buhos::Configuration[id]
    if conf.nil?
      nil
    else
      conf[:valor]
    end
  end
end



class SrTaxonomy < Sequel::Model

end

class SrTaxonomyCategory < Sequel::Model

end

class Systematic_Review_SRTC < Sequel::Model

end

class Institution < Sequel::Model

end

class GroupsUser < Sequel::Model
  many_to_one :user
  many_to_one :group
end


class RecordsReferences < Sequel::Model

end

class RecordsSearch < Sequel::Model

end