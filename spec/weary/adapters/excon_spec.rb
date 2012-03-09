require 'spec_helper'

describe Weary::Adapter::Excon do
  before do
    # WebMock.disable_net_connect!
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

    it "sets the body of the request" do
      stub_request(:post, @url)
      @request.method = "POST"
      @request.params :foo => "baz"
      req = Rack::Request.new(@request.env)
      described_class.connect(req)
      a_request(:post, @url).with(:body => "foo=baz").should have_been_made
    end
  end

  describe ".host_and_port_for_request" do
    it "cracks the Rack::Request open and returns a scheme + fqdn + port" do
      req = Rack::Request.new(@request.env)
      host_and_port = described_class.host_and_port_for_request(req)
      host_and_port.should == "http://github.com"
    end
    it "correctly picks the right scheme" do
      url = "https://github.com/hypomodern"
      request = Weary::Request.new url
      req = Rack::Request.new(request.env)
      host_and_port = described_class.host_and_port_for_request(req)
      host_and_port.should == "https://github.com"
    end
    it "correctly picks the right port" do
      url = "http://mytestserver.com:9292/"
      request = Weary::Request.new url
      req = Rack::Request.new(request.env)
      host_and_port = described_class.host_and_port_for_request(req)
      host_and_port.should == "http://mytestserver.com:9292"
    end
  end

  describe ".normalize_request_headers" do
    it "removes the HTTP_ prefix from request headers" do
      @request.headers 'User-Agent' => Weary::USER_AGENTS['Lynx 2.8.4rel.1 on Linux']
      headers = described_class.normalize_request_headers(@request.env)
      headers.should have_key "User-Agent"
    end
  end

  describe ".normalize_response_headers" do
    it "removes 'status' from the response headers" do
      original_headers = { 'Status' => '799', 'X-QUUX' => 'framulated' }
      headers = described_class.normalize_response_headers(original_headers)
      headers.should_not have_key "Status"
    end
  end

end