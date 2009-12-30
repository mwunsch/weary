require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Weary::Response do
  before do
    FakeWeb.register_uri(:get, "http://twitter.com", :body => get_fixture('twitter.xml'))
    FakeWeb.register_uri(:get, "http://github.com", :body => get_fixture('github.yml'))
  end
  
  after do
    FakeWeb.clean_registry
  end
  
  it 'wraps a raw Net::HTTPResponse' do
    FakeWeb.register_uri(:get, "http://vimeo.com", :body => get_fixture('vimeo.json'))
    
    request = Weary::Request.new('http://vimeo.com')
    response = request.perform
    response.raw.is_a?(Net::HTTPResponse).should == true
  end
  
  it 'stores the Request object that requested it' do
    FakeWeb.register_uri(:get, "http://vimeo.com", :body => get_fixture('vimeo.json'))
    
    request = Weary::Request.new('http://vimeo.com')
    response = request.perform
    response.requester.should == request
  end
  
  it 'has an HTTP code' do
    FakeWeb.register_uri(:get, "http://vimeo.com", :body => get_fixture('vimeo.json'), :status => http_status_message(418))
    
    request = Weary::Request.new('http://vimeo.com')
    response = request.perform
    response.code.should == 418
  end
  
  it 'has an HTTP message associated with it' do
    FakeWeb.register_uri(:get, "http://vimeo.com", :body => get_fixture('vimeo.json'), :status => http_status_message(418))
    
    request = Weary::Request.new('http://vimeo.com')
    response = request.perform
    response.message.should == "I'm a teapot"
  end
  
  it 'knows if the request cycle was successful' do
    FakeWeb.register_uri(:get, "http://vimeo.com", :body => get_fixture('vimeo.json'))
    
    request = Weary::Request.new('http://vimeo.com')
    response = request.perform
    response.success?.should == true
  end
  
  it 'stores the HTTP header' do
    FakeWeb.register_uri(:get, "http://vimeo.com", :body => get_fixture('vimeo.json'), :Server => 'Apache')
    
    request = Weary::Request.new('http://vimeo.com')
    response = request.perform
    response.header['server'][0].should == 'Apache'
  end
  
  it 'stores the content-type of the response' do
    FakeWeb.register_uri(:get, "http://vimeo.com", :body => get_fixture('vimeo.json'), :'Content-Type' => 'text/json')
    
    request = Weary::Request.new('http://vimeo.com')
    response = request.perform
    response.content_type.should == 'text/json'
  end
  
  it 'stores the cookies sent by the response' do
    FakeWeb.register_uri(:get, "http://vimeo.com", :body => get_fixture('vimeo.json'), :'Set-Cookie' => 'cookie=true')
    
    request = Weary::Request.new('http://vimeo.com')
    response = request.perform
    response.cookie.should == 'cookie=true'
  end
  
  it 'stores the body of the response' do
    FakeWeb.register_uri(:get, "http://vimeo.com", :body => get_fixture('vimeo.json'))
    
    request = Weary::Request.new('http://vimeo.com')
    response = request.perform
    response.body.should == get_fixture('vimeo.json')
  end
  
  it 'normalizes the format type of the response' do
    FakeWeb.register_uri(:get, "http://vimeo.com", :body => get_fixture('vimeo.json'), :'Content-Type' => 'text/json')
    
    request = Weary::Request.new('http://vimeo.com')
    response = request.perform
    response.format.should == :json
  end
  
  it 'can follow redirects' do
    FakeWeb.register_uri(:get, "http://markwunsch.com", :status => http_status_message(301), :Location => 'http://redirected.com')
    FakeWeb.register_uri(:get, "http://redirected.com", :body => "Hello world")
    
    request = Weary::Request.new('http://markwunsch.com')
    request.follows = false
    response = request.perform
    response.code.should == 301
    response.follow_redirect.code.should == 200
    response.follow_redirect.body.should == "Hello world"
  end
  
  it 'stores the url' do
    FakeWeb.register_uri(:get, "http://vimeo.com", :body => get_fixture('vimeo.json'))
    
    request = Weary::Request.new('http://vimeo.com')
    response = request.perform
    response.url.to_s.should == 'http://vimeo.com'
  end
  
  describe 'Parsing' do
    it 'parses JSON' do
      FakeWeb.register_uri(:get, "http://vimeo.com", :body => get_fixture('vimeo.json'), :'Content-Type' => 'text/json')
      
      request = Weary::Request.new('http://vimeo.com')
      response = request.perform
      response.parse[0].class.should == Hash
      response.parse[0]['title'].should == '"The Noises Rest"'
    end
    
    it 'parses XML' do
      FakeWeb.register_uri(:get, "http://twitter.com", :body => get_fixture('twitter.xml'), :'Content-Type' => 'application/xml')
      
      request = Weary::Request.new('http://twitter.com')
      response = request.perform
      response.parse.class.should == Hash
      response.parse['statuses'].size.should == 20
    end
    
    it 'parses YAML' do
      FakeWeb.register_uri(:get, "http://github.com", :body => get_fixture('github.yml'), :'Content-Type' => 'text/yaml')
      
      request = Weary::Request.new('http://github.com')
      response = request.perform
      response.parse.class.should == Hash
      response.parse['repository'][:name].should == 'rails'
    end
    
    it 'can parse with the [] method' do
      FakeWeb.register_uri(:get, "http://github.com", :body => get_fixture('github.yml'), :'Content-Type' => 'text/yaml')
      
      request = Weary::Request.new('http://github.com')
      response = request.perform
      response['repository'][:name].should == 'rails'
    end
  end
  
  describe 'Exceptions' do
    it 'raises an exception if there is a Server Error' do
      FakeWeb.register_uri(:get, "http://github.com", :status => http_status_message(500))
      
      request = Weary::Request.new('http://github.com')
      response = request.perform
      lambda { response.parse }.should raise_error
    end
    
    it 'raises an exception if there is a Client Error' do
      FakeWeb.register_uri(:get, "http://github.com", :status => http_status_message(404))
      
      request = Weary::Request.new('http://github.com')
      response = request.perform
      lambda { response.parse }.should raise_error
    end
  end
  
end