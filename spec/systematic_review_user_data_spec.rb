require_relative 'spec_helper'

describe SystematicReviewUserData do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    configure_empty_database
  end

  let(:user) { User.first }
  let(:review) { SystematicReview.create(name: 'User data review', group_id: Group.first.id) }

  after do
    SystematicReviewUserData.dataset.delete
    SystematicReview.where(name: 'User data review').each(&:delete)
  end

  after(:all) do
    close_sqlite
  end

  it 'stores defaults and associates the user with the review in both directions' do
    data = described_class.create(user_id: user.id, systematic_review_id: review.id).refresh

    expect(data.invitation_sent).to eq(false)
    expect(data.dashboard_order).to eq(0)
    expect(data.user).to eq(user)
    expect(data.systematic_review).to eq(review)
    expect(user.systematic_review_user_data).to include(data)
    expect(review.systematic_review_user_data).to include(data)
  end

  it 'persists invitation status and dashboard order' do
    data = described_class.create(user_id: user.id, systematic_review_id: review.id)
    data.update(invitation_sent: true, dashboard_order: 3)

    expect(data.refresh.invitation_sent).to eq(true)
    expect(data.dashboard_order).to eq(3)
  end

  it 'rejects duplicate user and review pairs' do
    attributes = { user_id: user.id, systematic_review_id: review.id }
    described_class.create(attributes)

    expect { described_class.create(attributes) }.to raise_error(Sequel::UniqueConstraintViolation)
  end

  it 'removes user data when the review is deleted' do
    data = described_class.create(user_id: user.id, systematic_review_id: review.id)
    review.delete

    expect(described_class[data.id]).to be_nil
  end
end
