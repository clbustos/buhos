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

require_relative 'analysis_sr_stage'

# Provides methods for analysis of a stage on a systematic review
# Used by AnalysisSystematicReview
module AnalysisSrStageMixin
  def get_asrs(stage)
    Analysis_SR_Stage.new(@rs, stage)
  end
  # A hash, with key=cd_id and value= resolution
  def resolution_by_cd(stage)
    @resolution_by_cd_h ||= {}
    @resolution_by_cd_h[stage] ||= get_asrs(stage).resolutions_by_cd
  end
  # A hash, with key=cd_id and value= resolution commentary
  def resolution_commentary_by_cd(stage)
    @resolution_commentary_by_cd_h ||= {}
    @resolution_commentary_by_cd_h[stage] ||= get_asrs(stage).resolutions_commentary_by_cd
  end

  # Count how many DC belongs to each pattern
  def count_by_pattern(list)
    list.inject({}) {|ac, v|
      ac[v[1]] ||= 0
      ac[v[1]] += 1
      ac
    }
  end
  def resolution_pattern(stage)
    count_by_pattern(resolution_by_cd(stage))
  end
  # Se analiza cada cd y se cuenta cuantas decisions para cada type
  def decisions_by_cd(stage)

    @decisions_by_cd_h ||= {}
    @decisions_by_cd_h[stage] ||= get_asrs(stage).decisions_by_cd
  end

# Define cuantos CD están en cada patrón
  def decisions_pattern(stage)
    count_by_pattern(decisions_by_cd(stage))
  end

# provides a hash, with keys containing the users decisions and values
# with the pattern for resolutions
  def resolutions_f_pattern_decision(stage)
    cds = @rs.cd_id_by_stage(stage)
    rpc = resolution_by_cd(stage)
    dpc = decisions_by_cd(stage)
    cds.inject({}) {|ac, cd_id|
      patron = dpc[cd_id]
      ac[patron] ||= {"yes" => 0, "no" => 0, Resolution::NO_RESOLUTION => 0}
      ac[patron][rpc[cd_id]] += 1
      ac
    }
  end

  def cd_from_pattern(stage, patron)

    decisions_by_cd(stage).find_all {|v|
      v[1] == patron
    }.map {|v| v[0]}


  end

  # Who are the judges and how many decisions they take
  def user_decisions(stage)
    @rs.group_users.inject({}) {|ac, usuario|
      ac[usuario.id] = {usuario: usuario, adu: AnalysisUserDecision.new(@rs.id, usuario.id, stage)}
      ac
    }
  end


  def cd_rejected_id(stage)
    get_asrs(stage).cd_rejected_id
  end

  def cd_accepted_id(stage)
    get_asrs(stage).cd_accepted_id
  end

  def cd_screened_id(stage)
    get_asrs(stage).cd_screened_id
  end

  def outgoing_citations(stage, cd_id)
    get_asrs(stage).outcoming_citations cd_id
  end

  def incoming_citations(stage, cd_id)
    get_asrs(stage).incoming_citations cd_id
  end

  def cd_id_assigned_by_user(stage, user_id)
    get_asrs(stage).cd_id_assigned_by_user(user_id)
  end

  def cd_without_allocations(stage)
    get_asrs(stage).cd_without_allocations
  end

  def cd_without_abstract(stage)
    get_asrs(stage).cd_without_abstract
  end

  def stage_complete?(stage)
    get_asrs(stage).stage_complete?
  end

end
