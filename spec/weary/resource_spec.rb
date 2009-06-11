require 'rubygems'
gem 'rspec'
require 'spec'
require File.join(File.dirname(__FILE__), '../..', 'lib', 'weary')

describe Weary::Resource do
  before do
    @test = Weary::Resource.new("test")
  end
  
  it 'defaults to a GET request' do
    @test.via.should == :get
  end
  it 'should add requirements to the "with" array' do
    @test.requires = [:foo, :bar]
    @test.with.should == [:foo, :bar]
  end
  
  it 'with paramaters could be comma delimited strings' do
    @test.with = "foo", "bar"
    @test.with.should == [:foo, :bar]
  end
  
  it 'authenticates? should be boolean' do
    @test.authenticates = "foobar"
    @test.authenticates?.should == true
    @test.authenticates = false
    @test.authenticates?.should == false
  end
  
  it 'follows_redirects? should be boolean' do
    @test.follows = "false"
    @test.follows_redirects?.should == true
    @test.follows = false
    @test.follows_redirects?.should == false
  end
  
  it 'should be intelligent about crafting names' do
    @test.name = "foo bar \n"
    @test.name.should == "foo_bar"
  end
end