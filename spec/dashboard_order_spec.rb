require_relative 'spec_helper'

describe 'Dashboard review order' do
  before do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_database
    login_admin
    @user=User[1]
    group=@user.groups.first
    @first=SystematicReview.create(name: 'First ordered review', group_id: group.id)
    @second=SystematicReview.create(name: 'Second ordered review', group_id: group.id)
  end

  def review_ids
    @user.systematic_reviews.where(active: true).order(:id).select_map(:id)
  end

  it 'saves the personal order and renders it after reloading' do
    data=SystematicReviewUserData.create(user_id: @user.id, systematic_review_id: @first.id, invitation_sent: true)
    ids=review_ids.reverse
    post '/user/dashboard/order', review_ids: ids

    expect(last_response.status).to eq(204)
    expect(UserDashboardInfo.new(@user).active_systematic_reviews.map(&:id)).to eq(ids)
    expect(data.refresh.invitation_sent).to eq(true)
    expect(data.dashboard_order).to eq(ids.index(@first.id))
    get '/'
    expect(last_response).to be_ok
    cards=Nokogiri::HTML(last_response.body).css('#dashboard-reviews > .dashboard-review')
    expect(cards.map { |card| card['data-review-id'].to_i }).to eq(ids)
    expect(cards.css('.dashboard-drag-handle[draggable="true"]').size).to eq(ids.size)
  end

  it 'keeps another user order unchanged' do
    other=User[2]
    data=SystematicReviewUserData.create(user_id: other.id, systematic_review_id: @first.id, dashboard_order: 9)
    post '/user/dashboard/order', review_ids: review_ids.reverse

    expect(last_response.status).to eq(204)
    expect(data.refresh.dashboard_order).to eq(9)
  end

  it 'rejects duplicates, missing reviews and reviews outside the dashboard without writing' do
    inaccessible=SystematicReview.create(name: 'Outside dashboard', group_id: Group.create(name: 'Other group', group_administrator: @user.id).id)
    [review_ids + [inaccessible.id], [@first.id, @first.id], [@first.id], ['invalid']].each do |ids|
      post '/user/dashboard/order', review_ids: ids
      expect(last_response.status).to eq(400)
      expect(SystematicReviewUserData.count).to eq(0)
    end
  end
end
