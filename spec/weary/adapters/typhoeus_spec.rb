require 'spec_helper'

begin
  describe Weary::Adapter::Typhoeus do
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

    describe ".url_for" do
      it "cracks the Rack::Request open and returns a scheme + fqdn + port" do
        req = Rack::Request.new(@request.env)
        url = described_class.url_for(req)
        url.should == @url
      end
      it "correctly uses the right scheme" do
        input_url = "https://github.com/hypomodern"
        request = Weary::Request.new input_url
        req = Rack::Request.new(request.env)
        output_url = described_class.url_for(req)
        output_url.should == input_url
      end
      it "correctly uses the right port" do
        input_url = "http://mytestserver.com:9292/v1/foo"
        request = Weary::Request.new input_url
        req = Rack::Request.new(request.env)
        output_url = described_class.url_for(req)
        output_url.should == input_url
      end
    end

    describe ".normalize_request_headers" do
      it "removes the HTTP_ prefix from request headers" do
        @request.headers 'User-Agent' => Weary::USER_AGENTS['Lynx 2.8.4rel.1 on Linux']
        headers = described_class.normalize_request_headers(@request.env)
        headers.should have_key "User-Agent"
      end
    end

    # describe ".normalize_response_headers" do
    #   it "removes 'status' from the response headers" do
    #     original_headers = { 'Status' => '799', 'X-QUUX' => 'framulated' }
    #     headers = described_class.normalize_response_headers(original_headers)
    #     headers.should_not have_key "Status"
    #   end
    # end
  end
rescue LoadError => e
  warn <<-MSG
    [warn] Received a LoadError when attempting to load the Typhoeus adapter,
    and skipping the specs.

    #{e.message}

    Make sure Typhoeus is in the $LOAD_PATH.
  MSG
end