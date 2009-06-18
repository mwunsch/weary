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
  
  describe "Set Headers" do
    it "should be a hash of values to pass in the Request head"
  end
  
  describe "Common Request Paramaters" do
    it "should define with params that every resource inherits"
      # #always_with && #always_requires methods will set with/requires in
      # the prepare_resource method of Weary
    
    it "should be able to be a hash"
      # new feature of Resources
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