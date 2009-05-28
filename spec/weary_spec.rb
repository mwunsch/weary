require 'rubygems'
gem 'rspec'
require 'spec'
require File.join(File.dirname(__FILE__), '..', 'lib', 'weary')

describe Weary do
  before do
    @Test = Class.new
    @Test.instance_eval { extend Weary }
  end
  
  describe "default domain" do
    it 'should be set with a url' do
      @Test.on_domain("http://twitter.com/")
      @Test.domain.should == "http://twitter.com/"
    end
    
    it "should also be set by it's alias" do
      @Test.domain = "http://twitter.com/"
      @Test.domain.should == "http://twitter.com/"
    end
    
    it 'should raise an exception when a url is not present' do
      lambda { @Test.on_domain("foobar") }.should raise_error
    end
    
    it 'should only take the first url given' do
      @Test.on_domain("with http://google.com/ and http://yahoo.com/")
      @Test.domain.should == "http://google.com/"
    end
    
    it "should only accept http and https url's"
    
    it 'should place a closing slash at the end of the url if one is not present'
  end
  
  describe "default format" do
    it 'can be set' do
      @Test.as_format("xml")
      @Test.instance_variable_defined?(:@default_format).should == true
    end
    
    it "should also be set by it's alias" do
      @Test.format = "xml"
      @Test.instance_variable_defined?(:@default_format).should == true
    end
    
    it 'should be a symbol' do
      @Test.as_format("xml")
      @Test.instance_variable_get(:@default_format).class.should == Symbol
    end
    
    it 'should be one of the allowed formats'
    
    it 'should raise an error if it is not an allowed format'
  end
  
  describe "default url pattern" do
    it 'can be set' do
      @Test.construct_url("<domain><resource>.<format>")
      @Test.instance_variable_defined?(:@url_pattern).should == true
    end
    
    it "should also be set by it's alias" do
      @Test.url = "<domain><resource>.<format>"
      @Test.instance_variable_defined?(:@url_pattern).should == true
    end
    
    it 'should be a string' do
      @Test.construct_url(123)
      @Test.instance_variable_get(:@url_pattern).class.should == String
    end
  end
  
  describe "basic authentication credentials" do
  end
  
  describe "resource declaration" do
    it "should adds a new resource" do
      @Test.declare_resource("resource")
      @Test.resources[0].has_key?(:resource).should == true
    end
    
    it "should default to a GET request" do
      @Test.declare_resource("resource")[:resource][:via].should == :get
    end
    
    it "should default to JSON if no format is defined" do
      @Test.declare_resource("resource")[:resource][:in_format].should == :json
    end
    
    it "should use the declared format, if a specific format is not defined" do
      @Test.format = :xml
      @Test.declare_resource("resource")[:resource][:in_format].should == :xml
    end
    
    it "should override the default format with it's own format" do
      @Test.format = :xml
      @Test.declare_resource("resource",{:in_format => :yaml})[:resource][:in_format].should == :yaml
    end
    
    it "should form a url if there is a default pattern" do
      @Test.domain = "http://twitter.com/"
      @Test.declare_resource("resource")[:resource][:url].should == "http://twitter.com/resource.json"
    end
    
    it "should override the default pattern with it's own url" do
      @Test.domain = "http://twitter.com/"
      @Test.url = "<domain><resource>.<format>"
      @Test.declare_resource("resource",{:url => "http://foobar.com/<resource>"})[:resource][:url].should == "http://foobar.com/resource"
    end
    
    it "should be able to contain a set of allowed parameters" do
      @Test.declare_resource("resource",{:with => [:id]})[:resource][:with].empty?.should == false
    end
    
    it "should be able to contain a set of required parameters" do
      @Test.declare_resource("resource",{:requires => [:id]})[:resource][:requires].empty?.should == false
    end
    
    it "should merge required parameters into allowed parameters" do
      @Test.declare_resource("resource",{:requires => [:id]})[:resource][:with].empty?.should == false
    end
    
    it "should create a method for an instantiated object" do
      @Test.domain = "http://twitter.com/"
      @Test.declare_resource("resource")
      @Test.public_method_defined?(:resource).should == true
    end
  end
  
end