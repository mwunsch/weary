require 'spec_helper'

describe Weary::Adapter do
  subject { Class.new { include Weary::Adapter }.new }
  let(:env) {
    {
      "REQUEST_METHOD"=>"GET",
      "SCRIPT_NAME"=>"",
      "PATH_INFO"=>"/api/v2/json/repos/show/mwunsch/weary",
      "QUERY_STRING"=>nil,
      "SERVER_NAME"=>"github.com",
      "SERVER_PORT"=>80,
      "REQUEST_URI"=>"/api/v2/json/repos/show/mwunsch/weary"
    }
  }

  describe "#call" do
    it_behaves_like "a Rack application"
  end

  describe "#perform" do
    it "returns a Rack::Response" do
      subject.perform(env).should be_a Weary::Response
    end

    it "yields the response to a block" do
      code = nil
      subject.perform(env) {|response| code = response.status }
      code.should be >= 100
    end
  end

  describe "connect" do
    it "returns a Rack::Response" do
      subject.connect(Rack::Request.new(env)).should be_a Weary::Response
    end
  end
end