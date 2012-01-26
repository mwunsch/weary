require 'spec_helper'

describe Weary::Request do
  describe "#uri" do
    subject { described_class.new "http://github.com/api/v2/json/repos/show/mwunsch/weary" }

    it_behaves_like "a URI" do
      let(:uri) { subject.uri }
    end

    it "infers a port of 80" do
      subject.uri.inferred_port.should eql 80
    end

    it "has a scheme of http" do
      subject.uri.scheme.should eql 'http'
    end
  end

  describe "#uri=" do
    context "given a URI string" do
      subject { described_class.new "http://github.com/api/v2/json/user/show/mwunsch" }

      it "sets the request URI" do
        original_path = subject.uri.path
        new_path = "/api/v2/json/repos/show/mwunsch/weary"
        expect {
          subject.uri = "http://github.com#{new_path}"
        }.to change{subject.uri.path}.from(original_path).to(new_path)
      end
    end

    context "given a URI object" do
      subject { described_class.new "http://github.com/api/v2/json/user/show/mwunsch" }

      it "sets the request URI" do
        original_path = subject.uri.path
        new_path = "/api/v2/json/repos/show/mwunsch/weary"
        expect {
          subject.uri = URI("http://github.com#{new_path}")
        }.to change{subject.uri.path}.from(original_path).to(new_path)
      end
    end
  end

  describe "#method" do
    before do
      @uri = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
    end

    it "infers a GET request on initialization" do
      r = described_class.new @uri
      r.method.should eql "GET"
    end

    it "is a Rack-friendly token" do
      r = described_class.new @uri, :get
      r.method.should eql "GET"
    end
  end

  describe "#method=" do
    before do
      uri = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
      @request = described_class.new uri
    end

    it "transforms the http verb to a Rack-friendly token" do
      expect {
        @request.method = :head
      }.to change{ @request.method }.from('GET').to('HEAD')
    end
  end

  describe "#handler" do
  end

  describe "#env" do
    let(:request) { described_class.new "http://github.com/api/v2/json/repos/show/mwunsch/weary" }

    it_behaves_like "a Rack env" do
      subject { request.env }
    end

    it "includes the calling object in the hash" do
      request.env["weary.request"].should be request
    end

    it "infers a SERVER_PORT of 80" do
      request.env["SERVER_PORT"].should eql 80
    end

    it "pulls the query string out of the uri" do
      request.uri = "http://api.twitter.com/version/users/show.format?screen_name=markwunsch"
      request.env['QUERY_STRING'].should eql 'screen_name=markwunsch'
    end
  end

  describe "#headers" do
    subject { described_class.new "http://github.com/api/v2/json/repos/show/mwunsch/weary" }
    let(:hash) { {'User-Agent' => Weary::USER_AGENTS['Lynx 2.8.4rel.1 on Linux']} }

    it "sets headers for the request" do
      subject.headers(hash)
      subject.instance_variable_get(:@headers).should eql hash
    end

    it "gets previously set headers" do
      subject.headers(hash)
      subject.headers.should eql hash
    end

    it "updates the env with the Rack-friendly key" do
      subject.headers(hash)
      subject.env.should have_key('HTTP_USER_AGENT')
    end

    it "updates the env with its HTTP_* value" do
      subject.headers(hash)
      subject.env['HTTP_USER_AGENT'].should eql(hash.values.first)
    end
  end

  describe "#adapter" do
    subject { described_class.new "http://github.com/api/v2/json/repos/show/mwunsch/weary" }

    it "sets a new adapter to set the connection" do
      klass = Class.new { include Weary::Adapter }
      subject.adapter(klass)
      subject.adapter.should be klass
    end

    it "defaults to the Net::HTTP adapter" do
      subject.adapter.should be Weary::Adapter::NetHttp
    end
  end

  describe "#perform" do
    subject do
      url = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
      described_class.new url
    end

    before do
      stub_request(:get, subject.uri.to_s).
        to_rack(lambda{|env| [200, {'Content-Type' => 'text/html'}, ['']]})
    end

    it "returns a Weary::Response" do
      subject.perform.should be_a Weary::Response
    end

    it "accepts an optional block" do
      code = nil
      subject.perform {|response| code = response.status }.force
      code.should be >= 100
    end
  end

  describe "#call" do
    it_behaves_like "a Rack application" do
      subject {
        described_class.new "http://github.com/api/v2/json/repos/show/mwunsch/weary" do |req|
          req.adapter Class.new { include Weary::Adapter }
        end
      }
      let(:env) { subject.env }
    end
  end
end