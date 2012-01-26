require 'spec_helper'

describe Weary::Response do
  describe "#finish" do
    subject { Weary::Response.new [""], 200, {'Content-Type' => 'text/plain'} }
    it "provides a Rack tuple" do
      subject.finish.length.should be 3
    end
  end

  describe "#call" do
    it_behaves_like "a Rack application" do
      subject { Weary::Response.new [""], 200, {'Content-Type' => 'text/plain'}}
      let(:env) { Weary::Request.new("http://github.com/api/v2/json/repos/show/mwunsch/weary").env }
    end
  end

end