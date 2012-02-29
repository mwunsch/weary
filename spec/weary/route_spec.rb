require 'spec_helper'

describe Weary::Route do
  before do
    @client = Class.new(Weary::Client)
    @client.domain "https://api.github.com"
    @client.get(:list, "/user/repos") {|r| r.basic_auth! }
    @client.get(:user, "/users/{user}/repos")
    @client.post(:create, "/user/repos") {|r| r.basic_auth! }
    @client.get(:repo, "/repos/{user}/{repo}")
    @client.patch(:edit, "/repos/{user}/{repo}") {|r| r.basic_auth! }
    @resources = @client.resources
  end

  describe "#call" do
    it_behaves_like "a Rack application" do
      subject { described_class.new @resources.values, @client.domain }
      let(:env) { @resources[:list].request.env }
    end

    it "returns a 404 when the url can't be routed" do
      route = described_class.new @resources.values, @client.domain
      dummy = @resources[:list].dup
      dummy.url "http://foo.com/baz"
      status, header, body = route.call dummy.request.env
      status.should eql 404
    end

    it "returns a 405 when the request method is invalid" do
      route = described_class.new @resources.values, @client.domain
      bad_request = @resources[:list].request do |request|
        request.method = "PUT"
      end
      status, header, body = route.call bad_request.env
      status.should eql 405
    end

    it "returns a 403 (forbidden) when requirements are unmet" do
      dummy = @resources[:edit].dup
      dummy.required :name
      route = described_class.new [dummy], @client.domain
      env = @resources[:edit].request(:user => "mwunsch", :repo => "weary").env
      status, header, body = route.call(env)
      status.should eql 403
    end
  end

  describe "#route" do
    subject { described_class.new @resources.values, @client.domain }

    it "accepts a Rack::Request and returns the best resource" do
      req = @resources[:list].request
      rack_req = Rack::Request.new(req.env)
      subject.route(rack_req).should be @resources[:list]
    end

    it "raises a 404 (not found) error if no url can be matched" do
      dummy = @resources[:list].dup
      dummy.url "http://foo.com/baz"
      rack_req = Rack::Request.new(dummy.request.env)
      expect { subject.route(rack_req) }.to raise_error Weary::Route::NotFoundError
    end

    it "raises a 405 (not allowed) error if no request method can be matched" do
      bad_request = @resources[:list].request do |request|
        request.method = "PUT"
      end
      rack_req = Rack::Request.new(bad_request.env)
      expect { subject.route(rack_req) }.to raise_error Weary::Route::NotAllowedError
    end
  end
end