require 'weary/middleware/content_type'
require 'spec_helper'

describe Weary::Middleware::ContentType do
  describe "#call" do
    before do
      @url = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
      @request = Weary::Request.new @url, 'POST'
      stub_request :post, @request.uri.to_s
    end

    it_behaves_like "a Rack application" do
      subject { described_class.new(@request) }
      let(:env) { @request.env }
    end

    it "adds a Content-Type header to the request" do
      middleware = described_class.new(@request)
      middleware.call(@request.env)
      a_request(:post, @url).
        with {|req| req.headers.has_key?("Content-Type") }.
        should have_been_made
    end

    it "adds a Content-Length header to the request" do
      middleware = described_class.new(@request)
      middleware.call(@request.env)
      a_request(:post, @url).
        with {|req| req.headers.has_key?("Content-Length") }.
        should have_been_made
    end

  end
end
