require 'spec_helper'

describe Weary::Adapter do
  subject { Class.new { include Weary::Adapter }.new }
  let(:env) {
    req = Weary::Request.new("http://github.com/api/v2/json/repos/show/mwunsch/weary")
    req.env
  }

  describe "#call" do
    it_behaves_like "a Rack application"
  end

  describe "connect" do
    it "returns a Rack::Response" do
      subject.connect(Rack::Request.new(env)).should be_a Rack::Response
    end
  end
end