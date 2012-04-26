require 'weary/middleware/basic_auth'
require 'spec_helper'

describe Weary::Middleware::BasicAuth do
  describe "#call" do
    before do
      @request = Weary::Request.new("http://github.com/api/v2/json/repos/show/mwunsch/weary")
      @url = "http://mwunsch:secret@github.com/api/v2/json/repos/show/mwunsch/weary"
      stub_request :get, @url
    end

    it_behaves_like "a Rack application" do
      subject { described_class.new(@request, "mwunsch", "secret") }
      let(:env) { @request.env }
    end

    it "prepares the Authorization header for the request" do
      middleware = described_class.new(@request, "mwunsch", "secret")
      middleware.call(@request.env)
      a_request(:get, @url).should have_been_made
    end
  end
end
