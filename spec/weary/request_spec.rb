require File.join(File.dirname(__FILE__), '..', 'spec_helper')

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
  
  # replace with FakeWeb
  it "should perform the request and retrieve a response" do
    test = Weary::Request.new("http://foo.bar")
    method = test.method
    response = Weary::Response.new(mock_response(method, 301, {'Location' => 'http://bar.foo'}), method)
    test.stub!(:perform).and_return(response)
    test.perform.code.should == 301
    test.perform.redirected?.should == true
  end
  
  # replace with FakeWeb
  it "should follow redirects" do
    test = Weary::Request.new("http://foo.bar")
    method = test.method   
    response = Weary::Response.new(mock_response(method, 301, {'Location' => 'http://bar.foo'}), method)
    response.stub!(:follow_redirect).and_return Weary::Response.new(mock_response(method, 200, {}), method)
    test.stub!(:perform).and_return(response)
    test.perform.code.should == 301
    test.perform.redirected?.should == true
    test.perform.follow_redirect.code.should == 200
    # not exactly kosher.
  end
  
  it "should prepare an oauth scheme if a token is provided" do
    consumer = OAuth::Consumer.new("consumer_token","consumer_secret",{:site => 'http://foo.bar'})
    token = OAuth::AccessToken.new(consumer, "token", "secret")
    test = Weary::Request.new("http://foo.bar", :post, {:oauth => token})
    test.send(:request).oauth_helper.options[:token].should == token
    # seems a good a way as any to test if OAuth helpers have been added to the request
  end
  
  it 'set the credentials to basic authentication' do
    basic_auth = {:username => 'mark', :password => 'secret'}
    test = Weary::Request.new("http://foo.bar", :get, {:basic_auth => basic_auth})
    test.credentials.should == basic_auth
  end
  
  it 'sets the credentials to an oauth token' do
    consumer = OAuth::Consumer.new("consumer_token","consumer_secret",{:site => 'http://foo.bar'})
    token = OAuth::AccessToken.new(consumer, "token", "secret")
    test = Weary::Request.new("http://foo.bar", :post, {:oauth => token})
    test.credentials.should == token
  end
  
  it 'sets the body params' do
    body = {:options => "something"}
    test = Weary::Request.new("http://foo.bar", :post, {:body => body})
    test.with.should == body.to_params
    test2 = Weary::Request.new("http://foo.bar", :post, {:body => body.to_params})
    test2.with.should == body.to_params
  end
  
end