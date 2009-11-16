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
  
  describe 'Method' do
    before do
      @test.url = 'http://foo.bar'
      @test.with = :user, :message
      @test.requires = [:id]
      @test.headers = {"User-Agent" => Weary::UserAgents["Safari 4.0.2 - Mac"]}
    end
    
    it "prepares a method body to be eval'd" do
      # yeah this needs to be divided up into more testable objects
      @test.craft_methods.class.should == String
    end
  end
  
  it 'can convert to a hash' do
    @test.to_hash.has_key?(:test).should == true
  end
  
  
  
end