require_relative 'revision_sistematica'
require_relative 'seguridad'
require_relative 'canonico_documento'


class AllocationCd < Sequel::Model
  many_to_one :systematic_review    , :class=>SystematicReview
  many_to_one :user_name            , :class=>User
  many_to_one :canonical_document   , :class=>CanonicalDocument

  def self.update_assignation(rev_id, cds_id, user_id,stage, status=nil)
    current=AllocationCd.where(:systematic_review_id=>rev_id, :user_id=>user_id, :stage=>stage).map(:canonical_document_id)

    to_remove=current-cds_id
    to_add=cds_id-current
    $db.transaction do
      AllocationCd.where(:systematic_review_id=>rev_id, :user_id=>user_id, :stage=>stage, :canonical_document_id=>to_remove).delete
      to_add.each do |cd_id|
        AllocationCd.insert(:systematic_review_id=>rev_id, :user_id=>user_id, :stage=>stage, :canonical_document_id=>cd_id, :status=>status)
      end
    end
    user=User[user_id]
    result=Result.new()
    result.success(I18n::t(:result_assignation_cd_to_user, :added=>to_add.length, :removed=>to_remove.length, :user_name=>user[:name]))
    result
  end


end