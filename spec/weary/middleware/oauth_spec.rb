require 'weary/middleware/oauth'
require 'spec_helper'

describe Weary::Middleware::OAuth do
  describe "#call" do
    before do
      @request = Weary::Request.new("http://github.com/api/v2/json/repos/show/mwunsch/weary")
      stub_request :get, @request.uri.to_s
    end

    it_behaves_like "a Rack application" do
      subject { described_class.new(@request) }
      let(:env) { @request.env }
    end

  end
end
