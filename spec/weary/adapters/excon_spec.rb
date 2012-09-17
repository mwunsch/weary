require 'spec_helper'

describe Weary::Adapter::Excon do
  before do
    @url = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
    @request = Weary::Request.new @url
  end

  describe "class methods" do
    it_behaves_like "an Adapter" do
      before do
        stub_request(:get, @url).
           to_return(:status => 200, :body => "", :headers => {})
      end

      subject { described_class }
      let(:env) { @request.env }
    end

    describe ".call" do
      it "performs the request through the connect method" do
        described_class.stub(:connect) { Rack::Response.new("", 200, {})}
        described_class.should_receive :connect
        described_class.call(@request.env)
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
  end

  describe "#connect" do
    it "calls the class method `.connect`" do
      described_class.stub(:connect) { [200, {'Content-Type' => 'text/plain'}, [""]] }
      described_class.should_receive(:connect)
      described_class.new.connect(Rack::Request.new(@request.env))
    end
  end

  describe "#call" do
    it "uses the overriden `#connect` method" do
      instance = described_class.new
      instance.stub(:connect) { Rack::Response.new [""], 501, {"Content-Type" => "text/plain"} }
      instance.should_receive(:connect)
      instance.call(@request.env)
    end
  end

  it_behaves_like "an Adapter" do
    before do
      stub_request(:get, @url).
         to_return(:status => 200, :body => "", :headers => {})
    end

    subject { described_class }
    let(:env) { @request.env }
  end


end