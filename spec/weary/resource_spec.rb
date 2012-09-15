require 'spec_helper'

describe Weary::Resource do
  it_behaves_like "a Requestable" do
    url = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
    subject { described_class.new "GET", url }
  end

  describe "#url" do
    it "is an Addressable::Template" do
      url = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
      resource = Weary::Resource.new "GET", url
      resource.url.should be_an Addressable::Template
    end

    it "gets a previously set url" do
      url = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
      resource = Weary::Resource.new "GET", url
      resource.url.pattern.should eql url
    end

    it "sets a new url" do
      resource = Weary::Resource.new "GET", "http://api.twitter.com/version/users/show.json"
      url = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
      resource.url url
      resource.url.pattern.should eql url
    end

    it "accepts variables in the url" do
      url = "http://github.com/api/v2/json/repos/show/{user}/{repo}"
      resource = Weary::Resource.new "GET", url
      resource.url.variables.should include 'user'
    end

    it "accepts variables in the sinatra style" do
      url = "http://github.com/api/v2/json/repos/show/:user/:repo"
      resource = Weary::Resource.new "GET", url
      resource.url.variables.should include 'user'
    end

    it "accepts port numbers in the url" do
      url = "http://localhost:3000/api/v2/"
      resource = Weary::Resource.new "GET", url
      resource.url.variables.should_not include '3000'
    end
  end

  describe "#optional" do
    it "creates a list of optional parameters for the request" do
      url = "http://github.com/api/v2/json/repos/show/{user}/{repo}"
      resource = described_class.new "GET", url
      resource.optional :login, :token
      resource.optional.length.should be 2
    end
  end

  describe "#required" do
    it "creates a list of required parameters for the request" do
      url = "http://api.twitter.com/version/users/show.{format}"
      resource = described_class.new "GET", url
      resource.required :screen_name
      resource.required.length.should be 1
    end
  end

  describe "#defaults" do
    it "sets some default values for parameters" do
      url = "http://github.com/api/v2/json/repos/show/{user}/{repo}"
      resource = described_class.new "GET", url
      resource.defaults :user => "mwunsch", :repo => "weary"
      resource.defaults.should have_key :user
    end
  end

  describe "#use" do
    it "adds a middleware to the stack and passes them onto the request" do
      require 'rack/lobster'
      url = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
      resource = described_class.new "GET", url
      resource.use Rack::Lobster
      stack = resource.request.instance_variable_get :@middlewares
      stack.flatten.should include Rack::Lobster
    end
  end

  describe "#basic_auth!" do
    subject do
      url = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
      resource = described_class.new "GET", url
    end

    it "prepares the request to accept username and password parameters" do
      subject.basic_auth!
      req = subject.request :username => "mwunsch", :password => "secret"
      req.basic_auth.should be
    end

    it "allows the default credential params to be overriden" do
      subject.basic_auth! :login, :token
      req = subject.request :login => "mwunsch", :token=> "secret"
      req.basic_auth.should be
    end

    it "permits the credentials to be completely optional" do
      subject.basic_auth!
      req = subject.request
      req.basic_auth.should_not be
    end
  end

  describe "#oauth!" do
    subject do
      url = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
      resource = described_class.new "GET", url
    end

    it "prepares the request to accept consumer_key and token parameters" do
      subject.oauth!
      req = subject.request :consumer_key => "key", :token => "access"
      req.oauth.should be
    end

    it "allows the default oauth params to be overriden" do
      subject.oauth! :consumer, :access_token
      req = subject.request :consumer => "key", :access_token => "access"
      req.oauth.should be
    end

    it "permits the oauth parameters to be completely optional" do
      subject.oauth!
      req = subject.request
      req.oauth.should_not be
    end
  end

  describe "#authenticates?" do
    subject do
      url = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
      resource = described_class.new "GET", url
    end

    it "is false when the resource does not accept authentication" do
      subject.authenticates?.should be_false
    end

    it "is true when basic authentication has been declared" do
      subject.basic_auth!
      subject.authenticates?.should be_true
    end

    it "is true when OAuth has been declared" do
      subject.oauth!
      subject.authenticates?.should be_true
    end
  end

  describe "#expected_params" do
    it "contains the request's expected parameters" do
      url = "http://github.com/api/v2/json/repos/show/{user}/{repo}"
      resource = described_class.new "GET", url
      resource.required :foo
      resource.optional :baz
      resource.expected_params.size.should be 2
    end

    it "contains the keys of the resource's defaults" do
      url = "http://github.com/api/v2/json/repos/show/{user}/{repo}"
      resource = described_class.new "GET", url
      resource.defaults :foo => "baz"
      resource.expected_params.should include "foo"
    end
  end

  describe "#expects?" do
    it "is true if the parameter is expected by the request" do
      url = "http://github.com/api/v2/json/repos/show/{user}/{repo}"
      resource = described_class.new "GET", url
      resource.required :foo
      resource.should be_expects :foo
    end

    it "is false if the parameter is unexpected" do
      url = "http://github.com/api/v2/json/repos/show/{user}/{repo}"
      resource = described_class.new "GET", url
      resource.required :foo
      resource.should_not be_expects :baz
    end
  end

  describe "#requirements" do
    it "contains required parameters and url keys" do
      url = "http://github.com/api/v2/json/repos/show/{user}/{repo}"
      resource = described_class.new "GET", url
      resource.required :foo
      resource.requirements.size.should be 3
    end
  end

  describe "#meets_requirements?" do
    it "is true if the set of parameters meet the request requirements" do
      url = "http://github.com/api/v2/json/repos/show/{user}/{repo}"
      hash = { :user => "mwunsch", :repo => "weary" }
      resource = described_class.new "GET", url
      resource.should be_meets_requirements hash
    end

    it "is false if the parameters do not meet requirements" do
      url = "http://github.com/api/v2/json/repos/show/{user}/{repo}"
      hash = { :user => "mwunsch" }
      resource = described_class.new "GET", url
      resource.should_not be_meets_requirements hash
    end
  end

  describe "#request" do
    it "builds a request object" do
      url = "http://github.com/api/v2/json/repos/show/{user}/{repo}"
      resource = described_class.new "GET", url
      req = resource.request(:repo => "weary", :user => "mwunsch")
      req.should be_a Weary::Request
    end

    it "expands templated urls" do
      url = "http://github.com/api/v2/json/repos/show/{user}/{repo}"
      resource = described_class.new "GET", url
      req = resource.request(:repo => "weary", :user => "mwunsch")
      req.uri.to_s.should eql "http://github.com/api/v2/json/repos/show/mwunsch/weary"
    end

    it "raises an exception for missing requirements" do
      url = "http://github.com/api/v2/json/repos/show/{user}/{repo}"
      resource = described_class.new "GET", url
      expect { resource.request }.to raise_error Weary::Resource::UnmetRequirementsError
    end

    it "passes headers along to the request" do
      url = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
      resource = described_class.new "GET", url
      resource.headers 'User-Agent' => 'RSpec'
      resource.request.headers.should eql 'User-Agent' => 'RSpec'
    end

    it "passes parameters into the request body" do
      resource = described_class.new "GET", "http://api.twitter.com/version/users/show.json"
      resource.required :user_id
      req = resource.request :user_id => "markwunsch"
      req.params.should eql "user_id=markwunsch"
    end
  end
end
