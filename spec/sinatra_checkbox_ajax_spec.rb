require_relative 'spec_helper.rb'
require_relative '../lib/sinatra/xeditable_checkbox'
describe 'Sinatra::Xeditable_Checkbox::Checbox class ' do
  before do

    @url="/reference/change"
    @html_class="reference"
    @values={:first=>"First", :second=>"Second", third:"Third"}
  end
  let(:ssa) {Sinatra::Xeditable_Checkbox::Checkbox.new(@values,@url,@html_class)}

  context "when javascript is retrieved" do
    let(:js) {Sinatra::Xeditable_Checkbox::Checkbox.new(@values,@url,@html_class).javascript}
    it "javascript should include correct class" do
      expect(js).to include("$('.#{@html_class}')")

    end
    it "javascript should include correct url" do
      expect(js).to include("url:'#{@url}'")
    end

  end

  context "when html is retrieved with values" do
    let(:html) {Sinatra::Xeditable_Checkbox::Checkbox.new(@values,@url,@html_class).html(1,[:first, :second])}
    it "html should include correct data-value" do
      expect(html).to include("data-value='first,second'")
    end
    it "html should include correct data-pk" do
      expect(html).to include("data-pk='1'")
    end
    it "html should include correct values" do
      expect(html).to include("First, Second")
    end

  end

  context "when html is retrieved without values" do
    let(:html) {Sinatra::Xeditable_Checkbox::Checkbox.new(@values,@url,@html_class).html(1,nil)}
    it "html should include correct data-value" do
      expect(html).to include("data-value=''")
    end
    it "html should include correct data-pk" do
      expect(html).to include("data-pk='1'")
    end
    it "html should include correct values" do
      expect(html).to include(I18n::t(:empty))
    end

  end


end