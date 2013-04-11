require 'spec_helper'

describe "the opcount graph page", :type => feature do
  before :each do
    visit "/monitoring"
  end

  it "loads successfully" do
  	page.should have_content 'Monitoring'
    page.should have_content 'Opcount Graph'
    find('#graph_canvas').should be_visible
  end
end

describe "the op count data json page", :type => feature do
  it "is accessible" do
    visit "/monitoring/opcounts"
    page.should have_content '['
    page.should have_content ']'
  end
end