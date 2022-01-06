# Copyright (c) 2016-2022, Claudio Bustos Navarrete
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

class Tag < Sequel::Model
  def self.get_tag(name)
    tag=Tag.where(:text=>name).first
    if tag.nil?
      tag_id=Tag.insert(:text=>name)
      tag=Tag[tag_id]
    end
    tag
  end

  def delete_if_unused
    if TagInCd.where(:tag_id=>self[:id]).empty? and TagBwCd.where(:tag_id=>self[:id]).empty?
      Tag[self[:id]].delete
    end
  end
end

class T_Class < Sequel::Model

  def self.classes_documents(sr)
    T_Class.where(:systematic_review_id=>sr[:id], :type=>'document').or(:systematic_review_id=>sr[:id], :type=>'general')
  end
  def tags
    Tag.join(:tag_in_classes, tag_id: :id ).select_all(:tags).where(:tc_id=>self.id)
  end
  def allocate_tag(tag)
    tag_en_clase=TagInClass.where(:tag_id=>tag[:id],:tc_id=>self.id)
    if(tag_en_clase.empty?)
      TagInClass.insert(:tag_id=>tag[:id],:tc_id=>self.id)
    end

  end


  def deallocate_tag(tag)
    TagInClass.where(:tag_id=>tag[:id], :tc_id=>self.id).delete
  end
end


class TagInClass < Sequel::Model

end

