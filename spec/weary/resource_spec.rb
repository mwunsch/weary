require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Weary::Resource do
  before do
    @test = Weary::Resource.new("test")
  end
  
  describe 'Name' do
    it 'has a name' do
      @test.name.should == "test"
    end
    
    it 'replaces the whitespace in the name' do
      @test.name = " test number two"
      @test.name.should == "test_number_two"
      @test.name = "test\nthree"
      @test.name.should == "test_three"
    end
    
    it 'downcases everything' do
      @test.name = "TEST"
      @test.name.should == "test"
    end
    
    it 'is a string' do
      @test.name = :test
      @test.name.should == "test"
    end
  end
  
  describe 'Via' do
    it 'defaults as a GET request' do
      @test.via.should == :get
    end

    it 'normalizes HTTP request verbs' do
      @test.via = "POST"
      @test.via.should == :post
    end

    it 'remains a GET if the input verb is not understood' do
      @test.via = "foobar"
      @test.via.should == :get
    end
  end
  
  describe 'Parameters' do
    it 'is an array of params' do
      @test.with = [:uid, :date]
      @test.with.should == [:uid, :date]
      @test.with = :user, :message
      @test.with.should == [:user, :message]
    end
    
    it 'stores the params as symbols' do
      @test.with = "user", "message"
      @test.with.should == [:user, :message]
    end
    
    it 'defines required params' do
      @test.requires = [:uid, :date]
      @test.requires.should == [:uid, :date]
      @test.requires = :user, :message
      @test.requires.should == [:user, :message]
    end
    
    it 'stores the required params as symbols' do
      @test.requires = "user", "message"
      @test.requires.should == [:user, :message]
    end
    
    it 'required params inherently become passed params' do
      @test.requires = [:user, :message]
      @test.requires.should == [:user, :message]
      @test.with.should == [:user, :message]
    end
    
    it 'merges required params with optional params' do
      @test.with = [:user, :message]
      @test.requires = [:id, :time]
      @test.with.should == [:user, :message, :id, :time]
      @test.requires.should == [:id, :time]
    end
    
    it 'optional params should merge with required params' do
      @test.requires = [:id, :time]
      @test.with.should == [:id, :time]
      @test.with = [:user, :message]
      @test.requires.should == [:id, :time]
      @test.with.should == [:id, :time, :user, :message]
    end
  end
  
  describe 'Authenticates' do
    it 'defaults to false' do
      @test.authenticates?.should == false
    end
    
    it 'is always set to a boolean' do
      @test.authenticates = "foobar"
      @test.authenticates?.should == true
      @test.authenticates = "false"
      @test.authenticates?.should == true
    end
  end
  
  describe 'Redirection' do
    it 'defaults to true' do
      @test.follows?.should == true
    end
    
    it 'is always set to a boolean' do
      @test.follows = "foobar"
      @test.follows?.should == true
      @test.follows = "false"
      @test.follows?.should == true
      @test.follows = false
      @test.follows?.should == false
    end
  end
  
  describe 'URL' do
    it 'is a valid URI' do
      @test.url = 'http://foo.bar/foobar'
      @test.url.scheme.should == 'http'
      @test.url.host.should == 'foo.bar'
      @test.url.path.should == '/foobar'
      @test.url.normalize.to_s.should == 'http://foo.bar/foobar'
    end
    
    it "rejects fake url's" do
      lambda { @test.url = "this is not really a url" }.should raise_error
    end
  end
  
  describe 'Request Builder' do
    before do
      @test.url = 'http://foo.bar'
      @test.with = :user, :message
      @test.headers = {"User-Agent" => Weary::UserAgents["Safari 4.0.2 - Mac"]}
    end
    
    it "merges defaults in with passed params" do
      params = {:message => "Hello"}
      defaults = {:user => "me"}
      @test.setup_parameters(params, defaults).should == {:message => "Hello", :user => "me"}
      @test.setup_parameters(params).should == {:message => "Hello"}
    end
    
    it 'alerts if a required param is missing' do
      @test.requires = [:id]
      params = {:user => "me", :message => "Hello"}
      lambda { @test.find_missing_requirements(params) }.should raise_error
    end
    
    it 'removes unnecessary parameters' do
      params = {:message => "Hello", :user => "me", :foo => "bar"}
      @test.remove_unnecessary_params(params).should == {:message => "Hello", :user => "me"}
    end
    
    it 'prepares param options for the request' do
      params = {:user => "me", :message => "Hello"}
      @test.prepare_request_body(params)[:query].should == {:user => "me", :message => "Hello"}
      @test.prepare_request_body(params).has_key?(:body).should == false
      @test.via = :post
      @test.prepare_request_body(params)[:body].should == {:user => "me", :message => "Hello"}
      @test.prepare_request_body(params).has_key?(:query).should == false
    end
    
    it 'alerts if credentials are missing but authorization is required' do
      @test.authenticates = true
      lambda { @test.setup_authentication({}) }.should raise_error
    end
    
    it 'negotiates what form of authentication is used (basic or oauth)' do
      @test.authenticates = true
      basic_auth = {:username => "mwunsch", :password => "secret123"}
      oauth_consumer = OAuth::Consumer.new("consumer_token","consumer_secret",{:site => 'http://foo.bar'})
      oauth_token = OAuth::AccessToken.new(oauth_consumer, "token", "secret")
      
      basic_authentication = @test.setup_authentication({},basic_auth)
      oauth_authentication = @test.setup_authentication({},oauth_token)
      
      basic_authentication.has_key?(:basic_auth).should == true
      basic_authentication.has_key?(:oauth).should == false
      basic_authentication[:basic_auth].should == basic_auth
      
      oauth_authentication.has_key?(:oauth).should == true
      oauth_authentication.has_key?(:basic_auth).should == false
      oauth_authentication[:oauth].should == oauth_token
    end
    
    it 'sets request options' do
      setup = @test.setup_options({})
      
      setup.has_key?(:headers).should == true
      setup.has_key?(:no_follow).should == false
      setup[:headers].should == @test.headers
    end
    
    it 'sets redirection following options' do
      @test.follows = false
      setup = @test.setup_options({})
      
      setup[:no_follow].should == true
    end
    
    it 'sets parameter body options' do
      params = {:user => "me", :message => "Hello"}
      setup_get = @test.setup_options(params)
      
      setup_get.has_key?(:query).should == true
      setup_get[:query] == params
      
      @test.via = :post
      setup_post = @test.setup_options(params)
      
      setup_post.has_key?(:query).should == false
      setup_post.has_key?(:body).should == true
      setup_post[:body].should == params      
    end
    
    it 'sets up authentication options' do
      @test.authenticates = true
      basic_auth = {:username => "mwunsch", :password => "secret123"}
      oauth_consumer = OAuth::Consumer.new("consumer_token","consumer_secret",{:site => 'http://foo.bar'})
      oauth_token = OAuth::AccessToken.new(oauth_consumer, "token", "secret")
      setup_basic = @test.setup_options({}, basic_auth)
      setup_oauth = @test.setup_options({}, oauth_token)
      
      setup_basic[:basic_auth].should == basic_auth
      setup_oauth[:oauth].should == oauth_token
    end
    
    it 'builds a Request' do
      @test.authenticates = true
      @test.requires = [:id]
      params = {:user => "me", :message => "Hello", :bar => "foo"}
      defaults = {:id => 1234, :foo => "bar"}
      basic_auth = {:username => "mwunsch", :password => "secret123"}
      
      request = @test.build!(params, defaults, basic_auth)
      
      request.class.should == Weary::Request
      request.via.should == :get
      request.credentials.should == basic_auth
    end
  end
  
  it 'can convert to a hash' do
    @test.to_hash.has_key?(:test).should == true
  end
  
  
  
end