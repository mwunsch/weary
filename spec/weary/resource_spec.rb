require File.join(File.dirname(__FILE__), '..', 'spec_helper')

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
  
  it 'with params could be a hash' do
    @test.with = {:foo => "Foo", :bar => "Bar"}
    @test.with.should == {:foo => "Foo", :bar => "Bar"}
    @test.requires = [:id, :user]
    @test.with.should == {:bar=>"Bar", :user => nil, :foo => "Foo", :id => nil}
    @test.with = [:foo, :bar]
    @test.with.should == [:foo, :bar, :id, :user]
  end
  
  it 'authenticates? should be boolean' do
    @test.authenticates = "foobar"
    @test.authenticates?.should == true
    @test.authenticates = false
    @test.authenticates?.should == false
  end
  
  it "oauth should be boolean"
  it "oauth should override basic authentication"
  it "access token should contain an oauth token"
  
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
  
  it 'should only allow specified http methods' do
    @test.via = "Post"
    @test.via.should == :post
    lambda { @test.via = :foobar }.should raise_error
  end

  it 'format should be a symbol' do
    @test.format = "xml"
    @test.format.class.should == Symbol
  end
  
  it 'format should be an allowed format' do
    @test.format = 'text/json'
    @test.format.should == :json
    lambda { @test.format = :foobar }.should raise_error
  end
  
  it 'should be able to set Headers' do
    @test.headers = {'Content-Type' => 'text/html'}
    @test.headers.should == {'Content-Type' => 'text/html'}
  end
  
end