shared_examples_for "a Requestable" do

  describe "#adapter" do
    it "sets a new adapter to set the connection" do
      klass = Class.new { include Weary::Adapter }
      subject.adapter(klass)
      subject.adapter.should be klass
    end

    it "defaults to the Net::HTTP adapter" do
      subject.adapter.should be Weary::Adapter::NetHttp
    end
  end

  describe "#headers" do
    it "prepares headers for the request" do
      subject.headers 'User-Agent' => 'RSpec'
      subject.headers.should eql 'User-Agent' => 'RSpec'
    end
  end

  describe "#use" do
    it "adds a middleware to the stack" do
      subject.use Rack::Runtime, "RSpec"
      stack = subject.instance_variable_get :@middlewares
      stack.first.should include(Rack::Runtime, ["RSpec"])
    end
  end

  describe "#user_agent" do
    it "updates the #headers hash with a User-Agent" do
      subject.user_agent 'RSpec'
      subject.headers.should eql 'User-Agent' => 'RSpec'
    end
  end

  describe "#has_middleware?" do
    it "is true if the Request is set up to use a Middleware" do
      require 'rack/lobster'
      subject.use Rack::Lobster
      subject.should have_middleware
    end

    it "is false if no Middleware is attached to this Resource" do
      subject.should_not have_middleware
    end
  end

end