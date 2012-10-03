require 'spec_helper'
require 'rack/lobster'

describe Weary::Client do
  it_behaves_like "a Requestable" do
    subject { Class.new(Weary::Client) }
  end

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

  describe "::domain" do
    before do
      @url = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
    end

    subject { Class.new(Weary::Client) }

    it "prepends the domain to the path when creating resources" do
      repo = {:user => "mwunsch", :repo => "weary"}
      subject.domain "http://github.com/api/v2/json/repos"
      resource = subject.get :show, "/show/{user}/{repo}"
      resource.url.expand(repo).to_s.should eql @url
    end
  end

  describe "::optional" do
    before do
      @url = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
    end

    subject { Class.new(Weary::Client) }

    it "passes optional requirements to the resources" do
      param = :username
      subject.optional param
      resource = subject.get :show, @url
      resource.optional.should include param
    end
  end

  describe "::required" do
    before do
      @url = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
    end

    subject { Class.new(Weary::Client) }

    it "passes optional requirements to the resources" do
      param = :username
      subject.required param
      resource = subject.get :show, @url
      resource.required.should include param
    end
  end

  describe "::defaults" do
    before do
      @url = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
    end

    subject { Class.new(Weary::Client) }

    it "passes default parameters into the resources" do
      params = { :foo => "baz" }
      subject.defaults params
      resource = subject.get :show, @url
      resource.defaults.should eql params
    end
  end

  describe "::headers" do
    before do
      @url = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
    end

    subject { Class.new(Weary::Client) }

    it "passes headers into the resources" do
      header = {'User-Agent' => "RSpec"}
      subject.headers header
      resource = subject.get :show, @url
      resource.headers.should eql header
    end
  end

  describe "::use" do
    before do
      @url = "http://github.com/api/v2/json/repos/show/mwunsch/weary"
    end

    subject { Class.new(Weary::Client) }

    it "adds a middleware to a stack and passes it into subsequent requests" do
      subject.use Rack::Lobster
      subject.get :show, @url
      client = subject.new
      stack = client.show.instance_variable_get :@middlewares
      stack.flatten.should include Rack::Lobster
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

  describe "::route" do
    before do
      @client = Class.new(Weary::Client)
      @client.domain "https://api.github.com"
      @client.get(:list, "/user/repos") {|r| r.basic_auth! }
      @client.get(:user, "/users/{user}/repos")
      @client.post(:create, "/user/repos") {|r| r.basic_auth! }
      @client.get(:repo, "/users/{user}/{repo}")
      @client.patch(:edit, "/users/{user}/{repo}") {|r| r.basic_auth! }
    end

    it "returns a router for the resources" do
      @client.route.should be_a Weary::Route
    end
  end

  describe "::call" do
    before do
      @client = Class.new(Weary::Client)
      @client.domain "https://api.github.com"
      @client.get(:list, "/user/repos") {|r| r.basic_auth! }
      @client.get(:user, "/users/{user}/repos")
      @client.post(:create, "/user/repos") {|r| r.basic_auth! }
      @client.get(:repo, "/users/{user}/{repo}")
      @client.patch(:edit, "/users/{user}/{repo}") {|r| r.basic_auth! }
    end

    it_behaves_like "a Rack application" do
      subject { @client }
      let(:env) { @client.resources[:list].request.env }
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

    it "combines a @defaults instance_variable with params on method execution" do
      action = :show
      url = "http://github.com/api/v2/json/repos/show/{user}/{repo}"
      @klass.get action, url
      client = @klass.new
      client.instance_variable_set :@defaults, :user => "mwunsch", :repo => "weary"
      expect { client.send(action) }.to_not raise_error
    end

    it "forwards requestables on to the requests" do
      action = :show
      url = "http://github.com/api/v2/json/repos/show/{user}/{repo}"
      @klass.get action, url
      adapter = Class.new { include Weary::Adapter }
      client = @klass.new
      client.adapter adapter
      client.send(action, :user => "mwunsch", :repo => "weary").adapter.should eql adapter
    end

    it "accepts a block to further add requestables" do
      action = :show
      url = "http://github.com/api/v2/json/repos/show/{user}/{repo}"
      @klass.get action, url
      adapter = Class.new { include Weary::Adapter }
      client = @klass.new do |c|
        c.adapter adapter
      end
      client.send(action, :user => "mwunsch", :repo => "weary").adapter.should eql adapter
    end
  end

end