require 'spec_helper'

describe Weary::Adapter do
  subject { Class.new { include Weary::Adapter }.new }
  let(:env) {
    req = Weary::Request.new("http://github.com/api/v2/json/repos/show/mwunsch/weary")
    req.headers 'User-Agent' => Weary::USER_AGENTS['Lynx 2.8.4rel.1 on Linux']
    req.env
  }

  it_behaves_like "an Adapter"

  describe "#normalize_request_headers" do
    it "removes the HTTP_ prefix from request headers" do
      headers = subject.normalize_request_headers(env)
      headers.should have_key "User-Agent"
    end
  end
end