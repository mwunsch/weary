require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Weary::Batch do
  after do
    FakeWeb.clean_registry
  end
  
  it 'is a group of requests' do
    requests = [ Weary.get('http://twitter.com'),
                 Weary.get('http://github.com'),
                 Weary.get('http://vimeo.com'),
                 Weary.get('http://tumblr.com')]
    
    test = Weary::Batch.new(requests)
    test.requests.should == requests
  end
  
  it 'contains a pool of threads, left empty until processing' do
    requests = [ Weary.get('http://twitter.com'),
                 Weary.get('http://github.com'),
                 Weary.get('http://vimeo.com'),
                 Weary.get('http://tumblr.com')]
    
    test = Weary::Batch.new(requests)
    test.pool.blank?.should == true    
  end
  
  it 'performs requests in parallel' do
    resources = %w[http://twitter.com http://github.com http://vimeo.com http://tumblr.com]
    resources.each {|url| FakeWeb.register_uri :get, url, :body => 'Hello world' }
    
    requests = [ Weary.get('http://twitter.com'),
                 Weary.get('http://github.com'),
                 Weary.get('http://vimeo.com'),
                 Weary.get('http://tumblr.com')]
    
    test = Weary::Batch.new(requests)
    responses = test.perform
    responses.size.should == 4
    responses.each {|response| response.code.should == 200 }
  end
  
  describe 'Callbacks' do
    before do
      resources = %w[http://twitter.com http://github.com http://vimeo.com http://tumblr.com]
      resources.each {|url| FakeWeb.register_uri :get, url, :body => 'Hello world' }
      @requests = [ Weary.get('http://twitter.com'),
                   Weary.get('http://github.com'),
                   Weary.get('http://vimeo.com'),
                   Weary.get('http://tumblr.com')]
    end
    
    it 'stores the on_complete callback' do
      test = Weary::Batch.new(@requests)
      test.on_complete do
        'hello'
      end
      test.on_complete.call.should == 'hello'
    end
    
    it 'stores the before_send callback' do
      test = Weary::Batch.new(@requests)
      test.before_send do
        'hello'
      end
      test.before_send.call.should == 'hello'
    end
    
    
  end
end