require 'spec_helper'

describe Weary::Resource do
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
  end

  describe "#optional" do
    it "creates a list of optional parameters for the request" do
      url = "http://github.com/api/v2/json/repos/show/{user}/{repo}"
      resource = Weary::Resource.new "GET", url
      resource.optional :login, :token
      resource.optional.length.should be 2
    end
  end

  describe "#required" do
    it "creates a list of required parameters for the request" do
      url = "http://api.twitter.com/version/users/show.{format}"
      resource = Weary::Resource.new "GET", url
      resource.required :screen_name
      resource.required.length.should be 1
    end
  end

  describe "#defaults" do
    it "sets some default values for parameters" do
      url = "http://github.com/api/v2/json/repos/show/{user}/{repo}"
      resource = Weary::Resource.new "GET", url
      resource.defaults :user => "mwunsch", :repo => "weary"
      resource.defaults.should have_key :user
    end
  end

  describe "#headers" do
    it "prepares headers for the request" do
      url = "http://github.com/api/v2/json/repos/show/{user}/{repo}"
      resource = Weary::Resource.new "GET", url
      resource.headers 'User-Agent' => 'RSpec'
      resource.headers.should eql 'User-Agent' => 'RSpec'
    end
  end

  describe "#user_agent" do
    it "updates the #headers hash with a User-Agent" do
      url = "http://github.com/api/v2/json/repos/show/{user}/{repo}"
      resource = Weary::Resource.new "GET", url
      resource.user_agent 'RSpec'
      resource.headers.should eql 'User-Agent' => 'RSpec'
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
      req.body.should eql "user_id=markwunsch"
    end
  end
end