require 'spec_helper'

describe Weary::Client do
  describe "::resource" do
    before do
      @url = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
    end

    subject { Class.new(Weary::Client) }

    it "defines a user resource" do
      resource = subject.resource :show, "GET", @url
      resource.should be_a Weary::Resource
    end

    it "allows the resource to be further modified by a block" do
      new_url = "http://github.com/api/v2/json/repos/show/{user}/{repo}"
      resource = subject.resource :show, "GET", @url do |r|
        r.url new_url
      end
      resource.url.variables.size.should eql 2
    end
  end

  Weary::Client::REQUEST_METHODS.each do |request_method|
    describe "::#{request_method}" do
      before do
        @url = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
      end

      subject { Class.new(Weary::Client) }

      it "creates a class method named the same as the request method" do
        subject.should respond_to request_method
      end

      it "is a convenience method for ::resource" do
        upcase_method = request_method.to_s.upcase
        subject.stub(:resource) { Weary::Resource.new upcase_method, @url }
        subject.should_receive(:resource).with(:name, upcase_method, @url)
        subject.send(request_method, :name, @url) {|r| r.basic_auth! }
      end
    end
  end

  describe "::resources" do
    before do
      @url = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
    end

    subject { Class.new(Weary::Client) }

    it "is a map of all the resources of the class" do
      action = :show
      resource = subject.get action, @url
      subject.resources[action].should be resource
    end
  end

  describe "::[]=" do
    before do
      @url = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
    end

    subject { Class.new(Weary::Client) }

    it "stores a named Weary::Resource" do
      action = :show
      resource = Weary::Resource.new "GET", @url
      subject[action] = resource
      subject.resources[action].should be resource
    end

    it "raises an error if a resource is not passed" do
      action = :show
      expect { subject[action] = "not a resource" }.to raise_error(ArgumentError)
    end
  end

  describe "::[]" do
    before do
      @url = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
    end

    subject { Class.new(Weary::Client) }

    it "retrieves a stored resource" do
      action = :show
      resource = subject.get action, @url
      subject[action].should be resource
    end
  end

  describe "#initialize" do
    before do
      @url = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
      @klass = Class.new(Weary::Client)
    end

    it "responds to a method with the name of the resource" do
      action = :show_repo
      @klass.get action, @url
      client = @klass.new
      client.should respond_to action
    end

    it "returns a Weary::Request when calling the named method" do
      action = :show
      @klass.get action, @url
      client = @klass.new
      client.send(action).should be_a Weary::Request
    end

    it "generates a method for the resource that takes a set of parameters" do
      action = :show
      url = "http://github.com/api/v2/json/repos/show/{user}/{repo}"
      @klass.get action, url
      client = @klass.new
      request = client.send(action, :user => "mwunsch", :repo => "weary")
      request.uri.to_s.should eql @url
    end
  end

end