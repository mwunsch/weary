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

    it "performs the request through the connect method" do
      described_class.stub(:connect) { Rack::Response.new("", 200, {})}
      described_class.should_receive :connect
      described_class.call(@request.env)
    end
  end

  describe "#call" do
    it "calls the class method `.call`" do
      described_class.stub(:call) { [200, {'Content-Type' => 'text/plain'}, [""]] }
      described_class.should_receive(:call)
      described_class.new.call(@request.env)
    end
  end

  describe ".connect" do
    before do
      stub_request(:get, @url)
    end

    it "performs the http request" do
      req = Rack::Request.new(@request.env)
      described_class.connect(req)
      a_request(:get, @url).should have_been_made
    end

    it "returns a Rack::Response" do
      req = Rack::Request.new(@request.env)
      described_class.connect(req).should be_kind_of Rack::Response
    end

    it "sets appropriate request headers" do
      @request.headers 'User-Agent' => Weary::USER_AGENTS['Lynx 2.8.4rel.1 on Linux']
      req = Rack::Request.new(@request.env)
      described_class.connect(req)
      a_request(:get, @url).with(:headers => @request.headers).should have_been_made
    end

    it "authenticates to the server"

    it "sets the body of the request"
  end

  describe ".normalize_request_headers" do
    it "removes the HTTP_ prefix from request headers" do
      @request.headers 'User-Agent' => Weary::USER_AGENTS['Lynx 2.8.4rel.1 on Linux']
      headers = described_class.normalize_request_headers(@request.env)
      headers.should have_key "User-Agent"
    end
  end

  describe ".socket" do
    it "sets up the http connection" do
      req = Rack::Request.new(@request.env)
      described_class.socket(req).should be_kind_of Net::HTTP
    end
  end

  describe ".request_class" do
    it "gets the Net::HTTP request class for the request method" do
      described_class.request_class("POST").should be Net::HTTP::Post
    end
  end
end