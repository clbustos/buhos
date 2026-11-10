require_relative 'spec_helper'

describe 'User deletion with related records' do
  include RSpecMixin

  before do
    configure_empty_database
    login_admin
    @target=User.create(login: 'delete_me', name: 'Delete me', password: 'hash', role_id: 'analyst')
    @review=SystematicReview.create(name: 'Preserved review', group_id: 1, sr_administrator: 1)
    GroupsUser.insert(group_id: 1, user_id: @target.id)
    SystematicReviewUserData.create(user_id: @target.id, systematic_review_id: @review.id)
    @invitation=Invitation.create(name: 'Invited', email: 'invited@example.com', token: SecureRandom.hex(32),
                                  sender_id: @target.id, systematic_review_id: @review.id)
    @message=Message.create(user_from: @target.id, user_to: 1, subject: 'Target message', text: 'Text')
    @reply=Message.create(user_from: 2, user_to: 1, subject: 'Reply', text: 'Reply', reply_to: @message.id)
    @unrelated=Message.create(user_from: 2, user_to: 1, subject: 'Preserved message', text: 'Keep')
    @sr_message=MessageSr.create(user_from: @target.id, systematic_review_id: @review.id, subject: 'SR message')
    @sr_reply=MessageSr.create(user_from: 2, systematic_review_id: @review.id, subject: 'SR reply', reply_to: @sr_message.id)
    MessageSrSeen.insert(m_rs_id: @sr_reply.id, user_id: 2, viewed: true)
    @analysis=:"analysis_sr_#{@review.id}"
    $db.create_table(@analysis) do
      primary_key :id
      foreign_key :user_id, :users, null: false
      String :answer
    end
    $db[@analysis].insert(user_id: @target.id, answer: 'Delete')
    $db[@analysis].insert(user_id: 2, answer: 'Keep')
  end

  def preview(ids=[@target.id])
    post '/admin/users/update', user: ids, action: 'delete'
    expect(last_response).to be_ok
    page=Nokogiri::HTML(last_response.body)
    @confirmation=page.at_css('input[name=confirmation]')['value']
    page
  end

  def confirm(ids=[@target.id])
    post '/admin/users/delete', users: ids.join(','), action: 'delete', confirmation: @confirmation, delete_related: '1'
  end

  it 'lists every affected table and count, including replies and extraction data, without deleting' do
    page=preview
    rows=page.css('#user-related-tables tbody tr').to_h do |row|
      [row.at_css('code').text, row.css('td').last.text.to_i]
    end
    expect(rows).to include('groups_users'=>1, 'systematic_review_user_data'=>1, 'invitations'=>1,
                            'messages'=>2, 'message_srs'=>2, 'message_sr_seens'=>1, @analysis.to_s=>1)
    expect(page.at_css('input[name=delete_related]')['required']).not_to be_nil
    expect(User[@target.id]).not_to be_nil
    expect(Message[@reply.id]).not_to be_nil
  end

  it 'deletes confirmed related records before the user and preserves unrelated records' do
    preview
    confirm
    expect(last_response).to be_redirect
    expect(User[@target.id]).to be_nil
    expect(Invitation[@invitation.id]).to be_nil
    expect(Message[@message.id]).to be_nil
    expect(Message[@reply.id]).to be_nil
    expect(MessageSr[@sr_message.id]).to be_nil
    expect(MessageSr[@sr_reply.id]).to be_nil
    expect(MessageSrSeen.count).to eq(0)
    expect(SystematicReviewUserData.where(user_id: @target.id).count).to eq(0)
    expect(GroupsUser.where(user_id: @target.id).count).to eq(0)
    expect($db[@analysis].all.map { |row| row[:answer] }).to eq(['Keep'])
    expect(Message[@unrelated.id]).not_to be_nil
    expect(SystematicReview[@review.id]).not_to be_nil
    expect(User[2]).not_to be_nil
  end

  it 'requires the related-data checkbox and a confirmation tied to the preview' do
    post '/admin/users/delete', users: @target.id.to_s, action: 'delete', delete_related: '1'
    expect(last_response).to be_ok
    expect(User[@target.id]).not_to be_nil
    preview
    post '/admin/users/delete', users: @target.id.to_s, action: 'delete', confirmation: @confirmation
    expect(last_response).to be_ok
    expect(User[@target.id]).not_to be_nil
  end

  it 'requests confirmation again if related records change after the preview' do
    preview
    Message.create(user_from: 1, user_to: @target.id, subject: 'New message')
    confirm
    expect(last_response).to be_ok
    expect(last_response.body).to include('Related data changed')
    expect(User[@target.id]).not_to be_nil
    expect(Message[@message.id]).not_to be_nil
  end

  it 'supports deleting multiple users and counts their shared related rows once' do
    second=User.create(login: 'delete_too', name: 'Delete too', password: 'hash', role_id: 'analyst')
    shared=Message.create(user_from: @target.id, user_to: second.id, subject: 'Shared message')
    ids=[@target.id, second.id]
    page=preview(ids)
    message_row=page.css('#user-related-tables tbody tr').find { |row| row.at_css('code').text == 'messages' }
    expect(message_row.css('td').last.text.to_i).to eq(3)
    confirm(ids)
    expect(last_response).to be_redirect
    expect(User.where(id: ids).count).to eq(0)
    expect(Message[shared.id]).to be_nil
    expect(Message[@unrelated.id]).not_to be_nil
  end

  it 'includes shared resources administered by the user and their dependencies' do
    group=Group.create(name: 'Owned group', group_administrator: @target.id)
    GroupsUser.insert(user_id: 2, group_id: group.id)
    @review.update(group_id: group.id)
    page=preview
    expect(page.text).to include('groups', 'systematic_reviews', 'even when other members also use them')
    plan=UserDeletionPlan.new([@target.id])
    expect(plan.related_tables).to include(table: @analysis, count: 2)
    confirm
    expect(last_response).to be_redirect
    expect(User[@target.id]).to be_nil
    expect(Group[group.id]).to be_nil
    expect(SystematicReview[@review.id]).to be_nil
    expect($db[@analysis].count).to eq(0)
    expect(User[2]).not_to be_nil
    expect(Group[1]).not_to be_nil
  end

  it 'rolls back deletion if any table cannot be deleted' do
    preview
    $db.run("CREATE TRIGGER prevent_user_deletion BEFORE DELETE ON users WHEN OLD.id = #{@target.id} BEGIN SELECT RAISE(ABORT, 'Test deletion failure'); END")
    confirm
    expect(last_response).to be_ok
    expect(last_response.body).to include('Changes were rolled back')
    expect(User[@target.id]).not_to be_nil
    expect(Invitation[@invitation.id]).not_to be_nil
    expect(Message[@reply.id].reply_to).to eq(@message.id)
    expect($db[@analysis].count).to eq(2)
  end

  it 'rejects direct deletion by an analyst, self deletion and invalid IDs' do
    post '/admin/users/delete', users: '1', action: 'delete'
    expect(last_response.status).to eq(403)
    post '/admin/users/delete', users: 'invalid', action: 'delete'
    expect(last_response.status).to eq(400)
    login_analyst
    post '/admin/users/delete', users: @target.id.to_s, action: 'delete', delete_related: '1'
    expect(last_response.status).to eq(403)
    expect(User[@target.id]).not_to be_nil
  end
end
