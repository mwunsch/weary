require File.join(File.dirname(__FILE__), 'spec_helper')

describe Weary do
  before do
    @test = Class.new
    @test.instance_eval { extend Weary }
  end
  
  describe 'Default Domain' do
    it 'should be set with a url' do
      @test.on_domain 'http://twitter.com/'
      @test.domain.should == 'http://twitter.com/'
    end
    
    it 'should raise an exception when a url is not present' do
      lambda { @test.on_domain("foobar") }.should raise_error
    end

    it 'should only take the first url given' do
      @test.on_domain("with http://google.com/ and http://yahoo.com/")
      @test.domain.should == "http://google.com/"
    end
  end
  
  describe 'Default Format' do
    it 'can be set' do
      @test.as_format(:xml)
      @test.instance_variable_get(:@default_format).should == :xml
    end
    
    it 'should be a recognized format' do
      @test.as_format('text/yaml')
      @test.on_domain('http://foobar.com/')
      @test.get('foobar').format.should == :yaml
    end
  end
  
  describe 'Default URL Pattern' do
    it 'can be set' do
      @test.construct_url("<domain><resource>.<format>")
      @test.instance_variable_defined?(:@url_pattern).should == true
    end

    it 'should be a string' do
      @test.construct_url(123)
      @test.instance_variable_get(:@url_pattern).class.should == String
    end
  end
  
  describe "Basic Authentication Credentials" do
    # i want to change this to be more specific about it being
    # basic authentication
    it "should accept a username and password" do
      @test.authenticates_with("foo","bar")
      @test.instance_variable_get(:@username).should == "foo"
      @test.instance_variable_get(:@password).should == "bar"
    end
  end
  
  describe "OAuth" do
    before do
      consumer = OAuth::Consumer.new("consumer_token","consumer_secret",{:site => 'http://foo.bar'})
      @token = OAuth::AccessToken.new(consumer, "token", "secret")
      @test.oauth @token
    end
    
    it "should accept an OAuth Access Token" do
      @test.instance_variable_get(:@oauth).should == @token
      lambda { @test.oauth "foobar" }.should raise_error
    end
    it "should notify the Resource that this is using OAuth" do
      @test.domain "http://foo.bar"
      r = @test.declare("show")
      r.oauth?.should == true
      r.access_token.should == @token
    end
    it "should be able to handle tokens set within the resource intelligently" do
      test = Class.new
      test.instance_eval { extend Weary }
      test.domain "http://foo.bar"
      r = test.declare("show")
      r.oauth?.should == false
      r.access_token.should == nil
      r.oauth = true
      lambda { test.send(:form_resource, r) }.should raise_error
      r.access_token = @token
      r.access_token.should == @token
      test.send(:form_resource, r)[:show][:oauth].should == true
      test.send(:form_resource, r)[:show][:access_token].should == @token
    end
  end
  
  describe "Set Headers" do
    it "should be a hash of values to pass in the Request head" do
      @test.on_domain "http://foo.bar"
      @test.set_headers "Content-Type" => "text/html"
      r = @test.get "resource"
      r.headers.should == {"Content-Type"=>'text/html'}
    end
  end
  
  describe "Common Request Paramaters" do
    it "should define with params that every resource inherits" do
      @test.on_domain "http://foo.bar"
      @test.always_with [:login, :token]
      r = @test.get "resource"
      r.with.should == [:login, :token]
      r.requires = [:foobar]
      r.with.should == [:login, :token, :foobar]
    end
    
    it "should be able to be a hash" do
      @test.on_domain "http://foo.bar"
      @test.always_with :foo => "Foo", :bar => "Bar"
      r = @test.get "resource"
      r.with.should == {:foo => "Foo", :bar => "Bar"}
      r.requires = [:foobar]
      r.with.should == {:foo => "Foo", :bar => "Bar", :foobar => nil}
    end
  end
  
  describe 'Resource Declaration' do
    before do
      @test.on_domain "http://foobar.com/"
    end
    
    it 'should add a new resource' do
      @test.get "resource"
      @test.resources[0].has_key?(:resource).should == true
    end
    
    it 'should instantiate a Resource object' do
      @test.get("resource").class.should == Weary::Resource
    end
    
    it 'should craft code to be evaluated' do
      r = @test.get("resource")
      @test.send(:craft_methods, r).class.should == String
    end
    
    it 'should define new instance methods' do
      @test.get("resource")
      @test.public_method_defined?(:resource).should == true
    end
    
    it 'should use sensible default formats' do
      @test.get("resource").format.should == :json
      @test.as_format(:xml)
      @test.post("foo").format.should == :xml
    end
  end
  
end