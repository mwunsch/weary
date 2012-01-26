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

  describe "#request" do
    it "builds a request object" do
      url = "http://github.com/api/v2/json/repos/show/{user}/{repo}"
      resource = Weary::Resource.new "GET", url
      resource.defaults :repo => "weary"
      resource.request :user => "mwunsch"
    end
  end
end