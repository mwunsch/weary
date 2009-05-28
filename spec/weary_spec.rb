require 'rubygems'
gem 'rspec'
require 'spec'
require File.join(File.dirname(__FILE__), '..', 'lib', 'weary')

describe Weary do
  describe "domain" do
    before(:each) do
      @test = Class.new
      @test.instance_eval { extend Weary }
    end
    
    it 'should be set with a url' do
      @test.on_domain("http://twitter.com/")
      @test.domain.should == "http://twitter.com/"
    end
    
    it 'should raise an exception when a url is not present' do
      lambda { @test.on_domain("foobar") }.should raise_error
    end
    
    it 'should only take the first url given' do
      @test.on_domain("with http://google.com/ and http://yahoo.com/")
      @test.domain.should == "http://google.com/"
    end
    
    it 'should only accept http and https url\'s'
    
    it 'should place a closing slash at the end if one is not present'
  end
end