require 'spec_helper'

describe Weary::Request do
  it_behaves_like "a Requestable" do
    subject { described_class.new "http://github.com/api/v2/json/repos/show/mwunsch/weary" }
  end

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

  describe "#env" do
    let(:request) { described_class.new "http://github.com/api/v2/json/repos/show/mwunsch/weary" }

    it_behaves_like "a Rack env" do
      subject { request.env }
    end

    it "includes the calling object in the hash" do
      request.env["weary.request"].should be request
    end

    it "infers a SERVER_PORT of 80" do
      request.env["SERVER_PORT"].should eql "80"
    end

    it "pulls the query string out of the uri" do
      request.uri = "http://api.twitter.com/version/users/show.format?screen_name=markwunsch"
      request.env['QUERY_STRING'].should eql 'screen_name=markwunsch'
    end
  end

  describe "#headers" do
    subject { described_class.new "http://github.com/api/v2/json/repos/show/mwunsch/weary" }
    let(:hash) { {'User-Agent' => Weary::USER_AGENTS['Lynx 2.8.4rel.1 on Linux']} }

    it "updates the env with the Rack-friendly key" do
      subject.headers(hash)
      subject.env.should have_key('HTTP_USER_AGENT')
    end

    it "updates the env with its HTTP_* value" do
      subject.headers(hash)
      subject.env['HTTP_USER_AGENT'].should eql(hash.values.first)
    end
  end

  describe "#params" do
    it "sets the query string for a GET request" do
      req = described_class.new "http://api.twitter.com/version/users/show.json"
      req.params :screen_name => 'markwunsch'
      req.uri.query.should eql "screen_name=markwunsch"
    end

    it "sets the rack input for a POST request" do
      req = described_class.new "https://api.github.com/gists", "POST"
      req.params :public => true
      req.env['rack.input'].read.should eql req.params
    end

    it "adds a Middleware to the stack for the Content-Type and Length" do
      req = described_class.new "https://api.github.com/gists", "POST"
      req.should_receive(:use).with(Weary::Middleware::ContentType)
      req.params :foo => "baz"
    end
  end

  describe "#json" do
    it "sets the request body to be a json string from a hash" do
      hash = {:foo => 'baz'}
      req = described_class.new "https://api.github.com/gists", "POST"
      req.json hash
      req.env['rack.input'].read.should eql MultiJson.encode(hash)
    end
  end

  describe "#basic_auth" do
    it "adds a Middleware to the stack to handle authentication" do
      req = described_class.new "https://api.github.com/gists", "POST"
      cred = ["mwunsch", "secret-passphrase"]
      req.should_receive(:use).with(Weary::Middleware::BasicAuth, cred)
      req.basic_auth *cred
    end

    it "returns true if auth has been set" do
      req = described_class.new "https://api.github.com/gists", "POST"
      cred = ["mwunsch", "secret-passphrase"]
      req.basic_auth *cred
      req.basic_auth.should be_true
    end
  end

  describe "#oauth" do
    it "adds a Middleware to the stack to sign the request" do
      req = described_class.new "https://api.github.com/gists", "POST"
      cred = ["consumer_key", "access_token"]
      expected = {:consumer_key => cred.first, :token => cred.last}
      req.should_receive(:use).with(Weary::Middleware::OAuth, [expected])
      req.oauth *cred
    end

    it "returns true if auth has been set" do
      req = described_class.new "https://api.github.com/gists", "POST"
      cred = ["consumer_key", "access_token"]
      req.oauth *cred
      req.oauth.should be_true
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

    it "returns a future containing a Weary::Response" do
      subject.perform.should be_a Weary::Response
    end

    it "accepts an optional block" do
      code = nil
      subject.perform {|response| code = response.status }.force
      code.should be >= 100
    end
  end

  describe "#use" do
    it "runs middleware through the calling stack" do
      req = described_class.new "http://github.com/api/v2/json/repos/show/mwunsch/weary"
      req.adapter(Class.new { include Weary::Adapter })
      # Rack::Runtime sets an "X-Runtime" response header
      # http://rack.rubyforge.org/doc/Rack/Runtime.html
      req.use Rack::Runtime, "RSpec"
      code, headers, body = req.call({})
      headers.should have_key "X-Runtime-RSpec"
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