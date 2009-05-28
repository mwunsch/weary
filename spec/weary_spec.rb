require 'rubygems'
gem 'rspec'
require 'spec'
require File.join(File.dirname(__FILE__), '..', 'lib', 'weary')

describe Weary do
  before do
    @test = Class.new
    @test.instance_eval { extend Weary }
  end
  
  describe "default domain" do
    it 'should be set with a url' do
      @test.on_domain("http://twitter.com/")
      @test.domain.should == "http://twitter.com/"
    end
    
    it "should also be set by it's alias" do
      @test.domain = "http://twitter.com/"
      @test.domain.should == "http://twitter.com/"
    end
    
    it 'should raise an exception when a url is not present' do
      lambda { @test.on_domain("foobar") }.should raise_error
    end
    
    it 'should only take the first url given' do
      @test.on_domain("with http://google.com/ and http://yahoo.com/")
      @test.domain.should == "http://google.com/"
    end
    
    it "should only accept http and https url's"
    
    it 'should place a closing slash at the end of the url if one is not present'
  end
  
  describe "default format" do
    it 'can be set' do
      @test.as_format("xml")
      @test.instance_variable_defined?(:@default_format).should == true
    end
    
    it "should also be set by it's alias" do
      @test.format = "xml"
      @test.instance_variable_defined?(:@default_format).should == true
    end
    
    it 'should be a symbol' do
      @test.as_format("xml")
      @test.instance_variable_get(:@default_format).class.should == Symbol
    end
    
    it 'should be one of the allowed formats'
    
    it 'should raise an error if it is not an allowed format'
  end
  
  describe "default url pattern" do
    it 'can be set' do
      @test.construct_url("<domain><resource>.<format>")
      @test.instance_variable_defined?(:@url_pattern).should == true
    end
    
    it "should also be set by it's alias" do
      @test.url = "<domain><resource>.<format>"
      @test.instance_variable_defined?(:@url_pattern).should == true
    end
    
    it 'should be a string' do
      @test.construct_url(123)
      @test.instance_variable_get(:@url_pattern).class.should == String
    end
  end
  
  describe "basic authentication credentials" do
    it "should accept a username and password" do
      @test.authenticates_with("foo","bar")
      @test.instance_variable_get(:@username).should == "foo"
      @test.instance_variable_get(:@password).should == "bar"
    end  
  end
  
  describe "resource declaration" do  
    before do
      @test.domain = "http://twitter.com/"
    end
    
    it "should adds a new resource" do
      @test.declare_resource("resource")
      @test.resources[0].has_key?(:resource).should == true
    end
    
    it "should default to a GET request" do
      @test.declare_resource("resource")[:resource][:via].should == :get
    end
    
    it "should default to JSON if no format is defined" do
      @test.declare_resource("resource")[:resource][:in_format].should == :json
    end
    
    it "should use the declared format, if a specific format is not defined" do
      @test.format = :xml
      @test.declare_resource("resource")[:resource][:in_format].should == :xml
    end
    
    it "should override the default format with it's own format" do
      @test.format = :xml
      @test.declare_resource("resource",{:in_format => :yaml})[:resource][:in_format].should == :yaml
    end
    
    it "should form a url if there is a default pattern" do
      @test.declare_resource("resource")[:resource][:url].should == "http://twitter.com/resource.json"
    end
    
    it "should override the default pattern with it's own url" do
      @test.declare_resource("resource",{:url => "http://foobar.com/<resource>"})[:resource][:url].should == "http://foobar.com/resource"
    end
    
    it "should be able to contain a set of allowed parameters" do
      @test.declare_resource("resource",{:with => [:id]})[:resource][:with].empty?.should == false
    end
    
    it "should be able to contain a set of required parameters" do
      @test.declare_resource("resource",{:requires => [:id]})[:resource][:requires].empty?.should == false
    end
    
    it "should merge required parameters into allowed parameters" do
      @test.declare_resource("resource",{:requires => [:id]})[:resource][:with].empty?.should == false
    end
    
    it "should authenticate with username and password" do
      @test.authenticates_with("foo","bar")
      @test.declare_resource("resource",{:authenticates => true})[:resource][:authenticates].should == true      
    end
    
    it "should raise an exception if authentication is required but no credentials are supplied" do
      lambda do
        @test.declare_resource("resource",{:authenticates => true})
      end.should raise_error
    end
    
    it "should create a method for an instantiated object" do
      @test.declare_resource("resource")
      @test.public_method_defined?(:resource).should == true
    end
    
    it "the method it creates should return a Weary::Response" do
      @test.domain = "http://localhost:8888/"
      @test.declare_resource("test")
      t = @test.new
      t.test.class.should == Weary::Response
    end
    
  end 
end