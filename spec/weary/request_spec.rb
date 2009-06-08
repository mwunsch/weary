require 'rubygems'
gem 'rspec'
require 'spec'
require File.join(File.dirname(__FILE__), '../..', 'lib', 'weary')

describe Weary::Request do
  
  it "should contain a url" do
    test = Weary::Request.new("http://google.com")
    test.uri.is_a?(URI).should == true
  end
  
  it "should parse the http method" do
    test = Weary::Request.new("http://google.com", "POST")
    test.method.should == :post
  end
  
  it "should craft a Net/HTTP Request" do
    test = Weary::Request.new("http://google.com").send :http
    test.class.should == Net::HTTP
  end
  
  it "should follow redirects" do
    pending "Not sure how to test this"
  end
end