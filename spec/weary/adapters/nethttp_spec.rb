require 'spec_helper'

describe Weary::Adapter::NetHttp do
  before do
    @url = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
    @request = Weary::Request.new @url
  end

  describe ".call" do
    before do
      stub_request(:get, @url).
         to_return(:status => 200, :body => "", :headers => {})
    end

    it_behaves_like "a Rack application" do
      subject { described_class }
      let(:env) { @request.env }
    end
  end

  describe "#call" do
    it "calls the class method `.call`" do
      described_class.stub(:call) { [200, {'Content-Type' => 'text/plain'}, [""]] }
      described_class.should_receive(:call).with(@request.env)
      described_class.new.call(@request.env)
    end
  end

  describe ".perform" do
    it "performs the request through the connect method"
    it "returns a Rack::Response"
    it "yields the response to a block if given"
  end

  describe "#perform" do
    it "calls the class method `.perform`"
  end

  describe ".connect" do
    it "performs the http request"
    it "returns a Rack::Response"
  end

  describe ".socket" do
    it "sets up the http connection"
  end
end