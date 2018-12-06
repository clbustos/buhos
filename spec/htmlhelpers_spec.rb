require 'rspec'
require_relative 'spec_helper'
require_relative("../lib/html_helpers")
describe 'HTMLHelpers' do
  class HTMLHelpersFake
    include HTMLHelpers
    attr_accessor :mobile, :tooltip_js, :params

  end
  let(:htmlhelpers) { HTMLHelpersFake.new }


  describe "#select_year" do
    let(:select_tag) {htmlhelpers.select_year(name:'name', value:'2010', css_class:'class_class')}
    it "should return a correct select tag " do
      expect(select_tag).to include("<select name='name' class='class_class'>")
    end
    it "should return a closing tag " do
      expect(select_tag).to include("</select>")
    end

    it "should retrieve an option with current year selected" do
      expect(select_tag).to match(/<option.+value='2010'.+selected.+>\s*2010\s*<\/option>/)
    end
    it "should retrieve an option with 1900 not selected" do
      expect(select_tag).to match(/<option.+value='1900'\s*>\s*1900<\/option>/)
    end

  end
  describe "#tooltip" do
    it 'should change @tooltip_js attribute to true' do
      htmlhelpers.tooltip('oli')
      expect(htmlhelpers.tooltip_js).to be true
    end
    it 'should return javascript code if first used' do
      out=htmlhelpers.tooltip('oli')
      expect(out).to include('<script>')
    end
    it 'should not return javascript code if first used' do
      htmlhelpers.tooltip('oli')
      out=htmlhelpers.tooltip('oli')

      expect(out).to_not include('<script>')
    end
    it 'should return test inside opening and closing span tag' do
      out=htmlhelpers.tooltip('oli')
      expect(out).to match(/<span.+oli.+<\/span>/)
    end

  end
  describe '#url used with @mobile=true' do
    it 'add mob to the route' do
      htmlhelpers.mobile=true
      expect(htmlhelpers.url('/login')).to eq('/mob/login')
    end
  end
  describe '#url used with @mobile=false' do
    it 'add mob to the route' do
      htmlhelpers.mobile=false
      expect(htmlhelpers.url('/login')).to eq('/login')
    end
  end

  describe '#put_editable' do
    it 'should return 505 if value is null or empty string' do
      app_fake=OpenStruct.new
      app_fake.params={'value'=>'', 'pk'=>'1'}
      expect(htmlhelpers.put_editable(app_fake) {|id,val|}).to eq(505)
      app_fake.params={'value'=>nil, 'pk'=>'1'}
      expect(htmlhelpers.put_editable(app_fake) {|id,val|}).to eq(505)

    end
    it 'should return 505 if pk is null or empty string' do
      app_fake=OpenStruct.new
      app_fake.params={'value'=>'1', 'pk'=>''}
      expect(htmlhelpers.put_editable(app_fake) {|id,val|}).to eq(505)
      app_fake.params={'value'=>'1', 'pk'=>nil}
      expect(htmlhelpers.put_editable(app_fake) {|id,val|}).to eq(505)
    end

    it 'should return 200 if pk and value are not nil' do
      app_fake=OpenStruct.new
      app_fake.params={'value'=>'1', 'pk'=>1}
      expect(htmlhelpers.put_editable(app_fake) {|id,val|}).to eq(200)
    end

    it 'should call block with value and pk values' do
      app_fake=OpenStruct.new
      app_fake.params={'value'=>'value', 'pk'=>'pk'}
      htmlhelpers.put_editable(app_fake) do |id,val|
        expect(id).to eq('pk')
        expect(val).to eq('value')
      end

    end


  end


  describe '#a_editable' do
    it 'return correct a' do
      expect(htmlhelpers.a_editable('id','prefix', 'data_url', 'v', 'placeholder')).to eq("<a class='name_editable' data-pk='id' data-url='data_url' href='#' id='prefix-id' data-placeholder='placeholder'>v</a>")
    end
  end


  describe '#a_generic_editable' do
    it 'return correct a' do
      expect(htmlhelpers.a_generic_editable('other_name', 'id','prefix', 'data_url', 'v', 'placeholder')).to eq("<a class='other_name' data-pk='id' data-url='data_url' href='#' id='prefix-id' data-placeholder='placeholder'>v</a>")
    end
  end

  describe '#permission_a_editable' do
    it 'return a tag if permission is true' do
      expect(htmlhelpers.permission_a_editable(true, 'id','prefix', 'data_url', 'v', 'placeholder')).to eq("<a class='name_editable' data-pk='id' data-url='data_url' href='#' id='prefix-id' data-placeholder='placeholder'>v</a>")
    end
    it 'return value if permission is false' do
      expect(htmlhelpers.permission_a_editable(false, 'id','prefix', 'data_url', 'v', 'placeholder')).to eq("v")
      expect(htmlhelpers.permission_a_editable(false, 'id','prefix', 'data_url', nil, 'placeholder')).to eq("")

    end

  end


  it 'provides a_tag' do
    expect(htmlhelpers.a_tag("example.com","hola")).to eq("<a href='example.com'>hola</a>")
  end
  it 'provides a_tag_badge' do
    expect(htmlhelpers.a_tag_badge("example.com","1")).to eq("<a href='example.com'><span class='badge'>1</span></a>")
  end

  it 'provides lf_to_br' do
    expect(htmlhelpers.lf_to_br("first\nsecond")).to eq("first<br/>second")
  end

  it 'provides class_bootstrap_contextual' do
    expect(htmlhelpers.class_bootstrap_contextual(true,"pre","class","no_class")).to eq("pre-class")
    expect(htmlhelpers.class_bootstrap_contextual(false,"pre","class","no_class")).to eq("pre-no_class")
  end
  it 'provides bool_class' do
    expect(htmlhelpers.bool_class(nil,"yes","no","nil")).to eq("nil")
    expect(htmlhelpers.bool_class(true,"yes","no","nil")).to eq("yes")
    expect(htmlhelpers.bool_class(false,"yes","no","nil")).to eq("no")

  end

  it 'provides a_textarea_editable' do
    expect(htmlhelpers.a_textarea_editable("id", "pre", "url", "value", "df")).to eq("<a class='textarea_editable' data-pk='id' data-url='url' href='#' id='pre-id' data-placeholder='df'>value</a>")
  end
  it 'provides decision_class_bootstrap' do
    expect(htmlhelpers.decision_class_bootstrap(nil,'pre')).to eq("pre-default")
    expect(htmlhelpers.decision_class_bootstrap("yes",'pre')).to eq("pre-success")
    expect(htmlhelpers.decision_class_bootstrap("no",'pre')).to eq("pre-danger")
    expect(htmlhelpers.decision_class_bootstrap("undecided",'pre')).to eq("pre-warning")

    expect(htmlhelpers.decision_class_bootstrap(nil,nil)).to eq("default")
    expect(htmlhelpers.decision_class_bootstrap("yes",nil)).to eq("success")
    expect(htmlhelpers.decision_class_bootstrap("no",nil)).to eq("danger")
    expect(htmlhelpers.decision_class_bootstrap("undecided",nil)).to eq("warning")

  end
end