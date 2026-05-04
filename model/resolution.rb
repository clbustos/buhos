# Copyright (c) 2016-2025, Claudio Bustos Navarrete
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

require_relative 'canonical_document'
require_relative 'systematic_review'
require_relative 'document_report'

class Resolution < Sequel::Model
  RESOLUTION_ACCEPT='yes'
  RESOLUTION_REJECT='no'
  NO_RESOLUTION='NR'
  PREVIOUS_REJECT="PR"

  NAMES={
      RESOLUTION_ACCEPT=>:Included,
      RESOLUTION_REJECT=>:Rejected,
      NO_RESOLUTION=>:No_resolution,
      PREVIOUS_REJECT=>:Previous_reject
  }

  def self.get_name_resolution(x)
    x.nil? ? NO_RESOLUTION : NAMES[x]
  end

  def self.merge_canonical_documents(target_id, canonical_document_ids)
    where(canonical_document_id:canonical_document_ids).
      all.
      group_by {|resolution| [resolution[:systematic_review_id], resolution[:stage]]}.
      each_value do |resolutions|
        merge_resolution_group(target_id, canonical_document_ids, resolutions)
      end
  end

  def self.merge_resolution_group(target_id, canonical_document_ids, resolutions)
    retained=resolutions.find {|resolution| resolution[:canonical_document_id] == target_id} || resolutions.first
    resolution_values=resolutions.map {|resolution| resolution[:resolution]}.compact.uniq
    definitive_values=resolution_values & [RESOLUTION_ACCEPT, RESOLUTION_REJECT]

    where(
      systematic_review_id:retained[:systematic_review_id],
      stage:retained[:stage],
      canonical_document_id:canonical_document_ids
    ).delete

    if definitive_values.length > 1
      resolutions.map {|resolution| resolution[:user_id]}.uniq.each do |user_id|
        DocumentReport.report_conflicting_resolution(
          systematic_review_id:retained[:systematic_review_id],
          canonical_document_id:target_id,
          user_id:user_id
        )
      end
    else
      merged_values=retained.values.select {|column, _value| columns.include?(column)}
      merged_values[:canonical_document_id]=target_id
      merged_values[:resolution]=definitive_values.first || resolution_values.first
      insert(merged_values)
    end
  end

  def self.set_for_document(systematic_review_id:, canonical_document_id:, stage:, resolution:, user_id:, commentary:nil)
    return delete_for_document(systematic_review_id:systematic_review_id, canonical_document_id:canonical_document_id, stage:stage) if resolution == 'delete'
    raise ArgumentError, "Invalid resolution #{resolution}" unless [RESOLUTION_ACCEPT, RESOLUTION_REJECT].include?(resolution)

    $db.transaction(:rollback=>:reraise) do
      attributes={
        resolution:resolution,
        user_id:user_id,
        timestamp:DateTime.now
      }
      attributes[:commentary]=commentary unless commentary.nil?

      dataset=where(systematic_review_id:systematic_review_id, canonical_document_id:canonical_document_id, stage:stage)
      if dataset.empty?
        insert({
          systematic_review_id:systematic_review_id,
          canonical_document_id:canonical_document_id,
          stage:stage
        }.merge(attributes))
      else
        dataset.update(attributes)
      end

      DocumentReport.resolve_conflicting_resolution(
        systematic_review_id:systematic_review_id,
        canonical_document_id:canonical_document_id
      )
    end
  end

  def self.delete_for_document(systematic_review_id:, canonical_document_id:, stage:)
    dataset=where(systematic_review_id:systematic_review_id, canonical_document_id:canonical_document_id, stage:stage)
    return false if dataset.empty?

    dataset.delete
    true
  end

  def self.update_commentary_for_document(systematic_review_id:, canonical_document_id:, stage:, user_id:, commentary:)
    $db.transaction(:rollback=>:reraise) do
      dataset=where(systematic_review_id:systematic_review_id, canonical_document_id:canonical_document_id, stage:stage)
      if dataset.empty?
        insert(
          systematic_review_id:systematic_review_id,
          canonical_document_id:canonical_document_id,
          stage:stage,
          resolution:NO_RESOLUTION,
          user_id:user_id,
          commentary:commentary
        )
      else
        dataset.update(commentary:commentary)
      end
    end
  end
end
