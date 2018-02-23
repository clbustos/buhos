require 'rspec'
require_relative 'spec_helper'
require_relative '../lib/abstract_presentation'




describe 'AbstractPresentation class' do
  it 'could be initialized with' do
    @ap=AbstractPresentation.new
    expect(@ap.html_with_keywords).to eq ""
  end

  it 'should add br on newlines' do
    @text="a\nb"
    #@keywords=%w{key1 key2}
    @ap=AbstractPresentation.new(@text)
    expect(@ap.html_with_keywords).to eq("a<br/>b")
  end
  it "should add <strong> on keywords, by default" do
    @text="key1 key2 key3"
    @keywords=%w{key1 key2}
    @ap=AbstractPresentation.new(@text)
    @ap.keywords =@keywords
    expect(@ap.html_with_keywords).to eq("<strong>key1</strong> <strong>key2</strong> key3")
  end
  it "should replace strong with another tag" do
    @text="key1 key2 key3"
    @keywords=%w{key1 key2}
    @ap=AbstractPresentation.new(@text)
    @ap.keywords =@keywords
    @ap.tag_keyword ='em'
    expect(@ap.html_with_keywords).to eq("<em>key1</em> <em>key2</em> key3")
  end

  it "should add class to tag" do
    @text="key1 key2 key3"
    @keywords=%w{key1 key2}
    @ap=AbstractPresentation.new(@text)
    @ap.keywords =@keywords
    @ap.tag_keyword ='em'
    @ap.class_keyword ='alert'
    expect(@ap.html_with_keywords).to eq("<em class='alert'>key1</em> <em class='alert'>key2</em> key3")
  end

end