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
    # These tests reveal tight coupling with Response API, which may or may not be a good thing
    
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
    
    it 'authorizes with basic authentication' do
      message = 'You are authorized to do that.'
      FakeWeb.register_uri(:get, "http://markwunsch.com", :status => http_status_message(401))
      FakeWeb.register_uri(:get, "http://mark:secret@markwunsch.com", :body => message)
      
      test = Weary::Request.new("http://markwunsch.com")
      response = test.perform
      response.code.should == 401
      response.body.should_not == message
      test.credentials = {:username => 'mark', :password => 'secret'}
      response = test.perform
      response.code.should == 200
      response.body.should == message
    end
    
    it 'still authorizes correctly if redirected' do
      message = 'You are authorized to do that.'
      FakeWeb.register_uri(:get, "http://markwunsch.com", :status => http_status_message(401))
      FakeWeb.register_uri(:get, "http://mark:secret@markwunsch.com", :status => http_status_message(301), :Location => 'http://markwunsch.net')
      FakeWeb.register_uri(:get, "http://markwunsch.net", :status => http_status_message(401))
      FakeWeb.register_uri(:get, "http://mark:secret@markwunsch.net", :body => message)
      
      test = Weary::Request.new("http://markwunsch.com")
      test.credentials = {:username => 'mark', :password => 'secret'}
      response = test.perform
      response.code.should == 200
      response.body.should == message
    end
    
    it 'converts parameters to url query strings' do
      params = {:id => 'mark', :message => 'hello'}
      message = "Using FakeWeb with params of #{params.to_params}"
      FakeWeb.register_uri(:get, "http://markwunsch.com", :status => http_status_message(403))
      FakeWeb.register_uri(:get, "http://markwunsch.com?#{params.to_params}", :body => message)
      
      test = Weary::Request.new("http://markwunsch.com")
      test.with = params
      response = test.perform
      response.body.should == message
    end
    
    it 'sends query strings correctly when redirected' do
      params = {:id => 'mark', :message => 'hello'}
      message = "Using FakeWeb with params of #{params.to_params}"
      FakeWeb.register_uri(:get, "http://markwunsch.com", :status => http_status_message(403))
      FakeWeb.register_uri(:get, "http://markwunsch.net", :status => http_status_message(403))
      FakeWeb.register_uri(:get, "http://markwunsch.com?#{params.to_params}", :status => http_status_message(301), :Location => 'http://markwunsch.net')
      FakeWeb.register_uri(:get, "http://markwunsch.net?#{params.to_params}", :body => message)
      
      test = Weary::Request.new("http://markwunsch.com")
      test.with = params
      response = test.perform
      response.code.should == 200
    end
    
    it 'converts parameters to request body on post' do
      params = {:id => 'mark', :message => 'hello'}
      message = "Using FakeWeb with params of #{params.to_params}"
      FakeWeb.register_uri(:get, "http://markwunsch.com", :status => http_status_message(403))
      FakeWeb.register_uri(:post, "http://markwunsch.com", :body => message)
      
      test = Weary::Request.new("http://markwunsch.com")
      test.via = :post
      test.with = params
      response = test.perform
      response.code.should == 200
      response.body.should == message
      
      # No way of testing Request bodies with FakeWeb as of 1.2.7 
    end    
  
    describe 'Non-Blocking' do
    end
  end
  
  describe 'Callbacks' do
    after do
      FakeWeb.clean_registry
    end
    
    describe 'on_complete' do
      it 'stores the callback' do
        test = Weary::Request.new("http://markwunsch.com")
        test.on_complete do
          'hello'
        end
        test.on_complete.call.should == 'hello'
      end
      
      it 'accepts a block, and the block becomes the callback' do
        msg = "You did it!"
        FakeWeb.register_uri(:get, "http://markwunsch.com", :body => msg)
        test = Weary::Request.new("http://markwunsch.com")
        body = ""

        test.on_complete do |response|
          body = response.body
        end

        test.perform
        body.should == msg
      end

      it 'is overriden when a block is passed to the perform method' do
        msg = "You did it!"
        FakeWeb.register_uri(:get, "http://markwunsch.com", :body => msg)
        test = Weary::Request.new("http://markwunsch.com")
        body = ""

        test.on_complete do |response|
          body = response.body
        end
        test.perform
        body.should == msg

        test.perform do |response|
          body = 'Now it is different'
        end

        body.should == 'Now it is different'
      end
    end
    
    describe 'before_send' do
      it 'stores the callback' do
        test = Weary::Request.new("http://markwunsch.com")
        test.before_send do
          'hello'
        end
        test.before_send.call.should == 'hello'
      end
      
      it 'accepts a block, and the block becomes the callback' do
        msg = "You did it!"
        FakeWeb.register_uri(:get, "http://markwunsch.com", :body => msg)
        test = Weary::Request.new("http://markwunsch.com")
        body = ""

        test.before_send do
          body = msg
        end
        body.should_not == msg
        test.perform
        body.should == msg
      end
      
      it 'takes the Request as an argument, so it can be manipulate before sending' do
        hello = "Hello from FakeWeb"
        FakeWeb.register_uri(:get, "http://markwunsch.com", :status => http_status_message(301), :Location => 'http://redirected.com')
        FakeWeb.register_uri(:get, "http://redirected.com", :body => hello)
        
        test = Weary::Request.new("http://markwunsch.com")
        test.before_send do |req|
          req.follows = false
        end
        
        test.perform.code.should == 301
      end
    end
  end
  
end