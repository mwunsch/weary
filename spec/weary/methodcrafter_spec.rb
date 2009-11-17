require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Weary::MethodCrafter do
  before do
    @res = Weary::Resource.new("test")
    @res.url = 'http://foo.bar'
    @res.with = :user, :message
    @res.requires = [:id]
    @res.headers = {"User-Agent" => Weary::UserAgents["Safari 4.0.2 - Mac"]}
    @test = Weary::MethodCrafter.new(@res)
  end
  
  it 'saves the resource' do
    @test.resource.name.should == "test"
    @test.resource.with.should == [:user, :message, :id]
  end
  
  it 'prepares default params'
  
end