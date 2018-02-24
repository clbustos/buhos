require 'rspec'
require_relative("../lib/html_helpers")
describe 'HTMLHelpers module' do
  let(:htmlhelpers) { Class.new { extend HTMLHelpers } }


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