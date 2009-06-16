require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Weary::Response do
  before do
    @test = Weary::Response.new(mock_response, :get)
  end
  
  it 'should wrap a Net::Response' do
    @test.raw.is_a?(Net::HTTPResponse).should == true
  end
  
  it 'should store the HTTP method' do
    @test.method.should == :get
  end
  
  it 'should have an HTTP code' do
    @test.code.should == 200
  end
  
  it 'should have an HTTP message' do
    @test.message.should == "OK"
  end
  
  it 'should know if the request was successful' do
    @test.success?.should == true
  end
  
  it 'should parse JSON' do
    test = Weary::Response.new(mock_response(:get, 200, {'content-type' => 'text/json'}, get_fixture("vimeo.json")), :get)
    test.parse[0]["title"].should == "\"The Noises Rest\""
  end
  
  it 'should parse XML' do
    test = Weary::Response.new(mock_response(:get, 200, {'content-type' => 'text/xml'}, get_fixture("twitter.xml")), :get)
    test.parse.class.should == Hash
    test.parse['statuses'][0]['id'].should == "2186350626"
  end
  
  it 'should parse YAML' do
    test = Weary::Response.new(mock_response(:get, 200, {'content-type' => 'text/yaml'}, get_fixture("github.yml")), :get)
    test.parse.class.should == Hash
    test.parse["repository"][:name].should == "rails"
  end
  
  it 'should be able to search XML or HTML with Nokogiri' do
    test = Weary::Response.new(mock_response(:get, 200, {'content-type' => 'text/xml'}, get_fixture("twitter.xml")), :get)
    test.search("status:first > id").text.should == "2186350626"
  end
  
  it 'should use [] to parse the document' do
    test = Weary::Response.new(mock_response(:get, 200, {'content-type' => 'text/xml'}, get_fixture("twitter.xml")), :get).parse
    test['statuses'][0]['id'].should == "2186350626"
  end
  
  it 'should parse the document to a hash if we try to search a non-XMLish document' do
    test = Weary::Response.new(mock_response(:get, 200, {'content-type' => 'text/yaml'}, get_fixture("github.yml")), :get)
    test.search("foo bar").class.should == Hash
    test.search("foo bar")["repository"][:name].should == "rails"
  end
  
  it 'should raise an exception if there was a Server Error' do
    test = Weary::Response.new(mock_response(:get, 500), :get)
    lambda { test.parse }.should raise_error
  end
  
  it 'should raise an exception if there was a Client Error'  do
    test = Weary::Response.new(mock_response(:get, 404), :get)
    lambda { test.parse }.should raise_error
  end
  
  it 'should follow HTTP redirects' do
    test = Weary::Response.new(mock_response(:get, 301), :get)
    test.redirected?.should == true
  end
  
end