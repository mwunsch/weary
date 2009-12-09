require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Weary::Request do
  
  it 'creates a Net/HTTP connection' do
    test = Weary::Request.new("http://google.com")
    test.http.class.should == Net::HTTP
  end
  
  it 'maps to a Net/HTTPRequest class' do
    test = Weary::Request.new("http://google.com")
    test.request_preparation.class.should == Net::HTTP::Get
  end
  
  describe 'Request' do    
    it 'prepares a Net/HTTP request' do
      test = Weary::Request.new("http://google.com")
      test.request.class.should == Net::HTTP::Get
    end
    
    it 'prepares a body for POST' do
      test = Weary::Request.new("http://foo.bar", :post)
      test.with = {:name => "markwunsch"}
      req = test.request
      req.class.should == Net::HTTP::Post
      req.body.should == test.with
    end
    
    it 'sets up headers' do
      test = Weary::Request.new("http://foo.bar")
      test.headers = {"User-Agent" => Weary::UserAgents["Safari 4.0.2 - Mac"]}
      req = test.request
      req['User-Agent'].should == Weary::UserAgents["Safari 4.0.2 - Mac"]
    end
    
    it 'has an authorization header when basic auth is used' do
      test = Weary::Request.new("http://foo.bar")
      test.credentials = {:username => "mark", :password => "secret"}
      req = test.request
      req.key?('Authorization').should == true
    end
    
    it "prepares an oauth scheme if a token is provided" do
      consumer = OAuth::Consumer.new("consumer_token","consumer_secret",{:site => 'http://foo.bar'})
      token = OAuth::AccessToken.new(consumer, "token", "secret")
      test = Weary::Request.new("http://foo.bar", :post)
      test.credentials = token
      test.request.oauth_helper.options[:token].should == token
    end
  end
  
  describe 'Options' do
    it 'sets the credentials to basic authentication' do
      basic_auth = {:username => 'mark', :password => 'secret'}
      test = Weary::Request.new("http://foo.bar", :get, {:basic_auth => basic_auth})
      test.credentials.should == basic_auth
    end

    it 'sets the credentials to an oauth token' do
      consumer = OAuth::Consumer.new("consumer_token","consumer_secret",{:site => 'http://foo.bar'})
      token = OAuth::AccessToken.new(consumer, "token", "secret")
      test = Weary::Request.new("http://foo.bar", :post, {:oauth => token})
      test.credentials.should == token
    end

    it 'sets the body params' do
      body = {:options => "something"}
      test = Weary::Request.new("http://foo.bar", :post, {:body => body})
      test.with.should == body.to_params
      test2 = Weary::Request.new("http://foo.bar", :post, {:body => body.to_params})
      test2.with.should == body.to_params
    end

    it 'sets header values' do
      head = {"User-Agent" => Weary::UserAgents["Safari 4.0.2 - Mac"]}
      test = Weary::Request.new("http://foo.bar", :get, {:headers => head})
      test.headers.should == head
    end

    it 'sets a following value for redirection' do
      test = Weary::Request.new("http://foo.bar", :get, {:no_follow => true})
      test.follows?.should == false
      test = Weary::Request.new("http://foo.bar", :get, {:no_follow => false})
      test.follows?.should == true
      test = Weary::Request.new("http://foo.bar", :get)
      test.follows?.should == true
    end
    
    it 'uses the #with hash to create a URI query string if the method is a GET' do
      test = Weary::Request.new("http://foo.bar/path/to/something")
      test.with = {:name => "markwunsch", :title => "awesome"}
      test.uri.query.should == test.with
    end
  end
    
  describe 'Perform' do
    
    after do
      FakeWeb.clean_registry
    end
    
    it 'performs the request and gets back a response' do
      hello = "Hello from FakeWeb"
      FakeWeb.register_uri(:get, "http://markwunsch.com", :body => hello)
      
      test = Weary::Request.new("http://markwunsch.com")
      response = test.perform
      response.class.should == Weary::Response
      response.body.should == hello
    end
      
    it 'follows redirection' do
      hello = "Hello from FakeWeb"
      FakeWeb.register_uri(:get, "http://markwunsch.com", :status => http_status_message(301), :Location => 'http://redirected.com')
      FakeWeb.register_uri(:get, "http://redirected.com", :body => hello)
      
      test = Weary::Request.new("http://markwunsch.com")
      response = test.perform
      response.body.should == hello
    end
    
    it 'will not follow redirection if disabled' do
      hello = "Hello from FakeWeb"
      FakeWeb.register_uri(:get, "http://markwunsch.com", :status => http_status_message(301), :Location => 'http://redirected.com')
      FakeWeb.register_uri(:get, "http://redirected.com", :body => hello)
      
      test = Weary::Request.new("http://markwunsch.com", :get, :no_follow => true)
      response = test.perform
      response.code.should == 301
    end
    
    it 'passes the response into a callback' do
      hello = "Hello from FakeWeb"
      FakeWeb.register_uri(:get, "http://markwunsch.com", :body => hello)
      response_body = ""
      
      test = Weary::Request.new("http://markwunsch.com")
      test.perform do |response|
        response_body = response.body
      end
      
      response_body.should == hello
    end
    
    it 'performs the callback even when redirected' do
      hello = "Hello from FakeWeb"
      FakeWeb.register_uri(:get, "http://markwunsch.com", :status => http_status_message(301), :Location => 'http://redirected.com')
      FakeWeb.register_uri(:get, "http://redirected.com", :body => hello)
      
      response_body = ""
      
      test = Weary::Request.new("http://markwunsch.com")
      test.perform do |response|
        response_body = response.body
      end
      
      response_body.should == hello
    end
    
    # TODO: Test auth, and post bodies w redirect.
  end
  
  describe 'Callbacks' do
  end
  
end