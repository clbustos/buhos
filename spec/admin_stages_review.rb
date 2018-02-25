require 'spec_helper'

describe 'Stage administration' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_complete_sqlite
  end
  before(:each) do
    post '/login' , :user=>'admin', :password=>'admin'
  end
  let(:res_sta) {$db["SELECT resolucion,COUNT(*) as n FROM resoluciones WHERE revision_sistematica_id=1 and etapa='screening_title_abstract' GROUP BY resolucion"].to_hash(:resolucion) }
  let(:res_sr) {$db["SELECT resolucion,COUNT(*) as n FROM resoluciones WHERE revision_sistematica_id=1 and etapa='screening_references' GROUP BY resolucion"].to_hash(:resolucion) }
  let(:res_rft) {$db["SELECT resolucion,COUNT(*) as n FROM resoluciones WHERE revision_sistematica_id=1 and etapa='review_full_text' GROUP BY resolucion"].to_hash(:resolucion) }
  let(:press_accept_2_no_sta) {get '/review/1/stage/screening_title_abstract/pattern/yes_0__no_2__undecided_0__ND_0/resolution/yes'}
  let(:assign_all_to_admin_on_sta) {get '/review/1/stage/screening_title_abstract/add_assign_user/1/all'}
  let(:remove_all_assignations_to_admin_on_sta) {get '/review/1/stage/screening_title_abstract/rem_assign_user/1/all'}
  let(:assignations_admin) {$db["SELECT etapa, COUNT(*) as n FROM asignaciones_cds WHERE revision_sistematica_id=1 and usuario_id=1 GROUP BY etapa"].to_hash(:etapa)}

  context "when check number of resolution on each stage" do
    it "should have 22 yes resolutions on sta"  do expect(res_sta['yes'][:n]).to eq(22) end
    it "should have 63 no resolutions on sta"   do expect(res_sta['no'][:n]).to eq(63) end
    it "should have 9 yes resolutions on sr"   do expect(res_sr['yes'][:n]).to eq(9) end
    it "should have 18 no resolutions on sr"    do expect(res_sr['no'][:n]).to eq(18) end
    it "should have 27 yes resolutions on rft"  do expect(res_rft['yes'][:n]).to eq(27) end
    it "should have 3 no resolutions on rft"    do expect(res_rft['no'][:n]).to eq(3) end
  end
  context "when accept to 'yes' on 2 'no' decisions on sta" do
    it "should have 78 yes resolutions" do press_accept_2_no_sta; expect(res_sta['yes'][:n]).to eq(78) end
    it "should have 7 no resolutions"   do press_accept_2_no_sta; expect(res_sta['no'][:n]).to eq(7) end
  end

  context "when check assignations on each stage" do
    it "should have 85 for admin on sta" do expect(assignations_admin['screening_title_abstract'][:n]).to eq(85) end
    it "should have 26 for admin on sr" do expect(assignations_admin['screening_references'][:n]).to eq(26) end
    it "should have 30 for admin on rft" do expect(assignations_admin['review_full_text'][:n]).to eq(30) end

  end

  context "when assign all document for admin on sta" do
    it "should have 85 assignations on sta" do
      assign_all_to_admin_on_sta
      expect(assignations_admin['screening_title_abstract'][:n]).to eq(85)
    end
    it "should have 84 assignations on sta if we remove one later" do
      assign_all_to_admin_on_sta
      post '/canonical_document/user_assignation/desasignar', {rs_id:1, cd_id:64, user_id:1, stage:'screening_title_abstract'}

      expect(assignations_admin['screening_title_abstract'][:n]).to eq(84)
    end
  end

  context "when remove all assignations for admin on sta" do
    it "should have 0 assignations on sta" do
      remove_all_assignations_to_admin_on_sta
      expect(assignations_admin['screening_title_abstract']).to be_nil
    end
    it "should have 1 assignations on sta if we add one later" do
      remove_all_assignations_to_admin_on_sta
      post '/canonical_document/user_assignation/asignar', {rs_id:1, cd_id:64, user_id:1, stage:'screening_title_abstract'}

      expect(assignations_admin['screening_title_abstract'][:n]).to eq(1)
    end
  end

end