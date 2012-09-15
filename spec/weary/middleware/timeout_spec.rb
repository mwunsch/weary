require 'weary/middleware/timeout'
require 'spec_helper'

describe Weary::Middleware::Timeout do
  describe "#call" do
    before do
      @url = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
      @request = Weary::Request.new @url
      stub_request(:get, @request.uri.to_s).to_timeout
    end

    it_behaves_like "a Rack application" do
      subject { described_class.new(@request) }
      let(:env) { @request.env }
    end

    it "returns a 504 (Gateway Timeout) when no response is received in time" do
      middleware = described_class.new(@request)
      status, header, body = middleware.call(@request.env)
      status.should eql 504
    end

  end
end