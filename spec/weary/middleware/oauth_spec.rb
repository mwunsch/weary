require 'weary/middleware/oauth'
require 'spec_helper'

describe Weary::Middleware::OAuth do
  describe "#call" do
    before do
      @url = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
      @request = Weary::Request.new @url
      stub_request :get, @request.uri.to_s
    end

    it_behaves_like "a Rack application" do
      subject { described_class.new(@request, :consumer_key => "consumer_key", :token => "access_token") }
      let(:env) { @request.env }
    end

    it "prepares the Authorization header for the request" do
      middleware = described_class.new(@request, :consumer_key => "consumer_key", :token => "access_token")
      middleware.call(@request.env)
      signed_header = middleware.sign(@request.env)
      a_request(:get, @url).
        with {|req| req.headers.has_key?("Authorization") }.
        should have_been_made
    end

  end
end
