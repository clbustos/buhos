require 'rspec'
require 'sinatra'
require_relative 'spec_helper.rb'
require_relative '../lib/../lib/sinatra_xeditable_select'
describe 'Sinatra Select Ajax (with xeditable) presentation' do
  before do

    @url="/reference/change"
    @html_class="reference"
    @values={:nil=>"No option",:first=>"First", :second=>"Second"}
    @ssa=Sinatra::Xeditable_Select::Select.new(@values,@url,@html_class)
    @ssa.nil_value =:nil


  end
  it "javascript should include correct class" do
    expect(@ssa.javascript).to include("$('.#{@html_class}')")

  end
  it "javascript should include correct url" do
    expect(@ssa.javascript).to include("url:'#{@url}'")
  end
  it "html should include correct information for non nil value" do
    html_response=@ssa.html(1,:first)
    expect(html_response).to include("First")
    expect(html_response).to include("data-pk='#{1}'")
    expect(html_response).to include("data-value='first'")

  end
  it "html should include correct information for nil value" do
    html_response=@ssa.html(1,nil)
    expect(html_response).to include("No option")
    expect(html_response).to include("data-pk='#{1}'")
    expect(html_response).to include("data-value='nil'")

  end

end