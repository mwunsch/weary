require File.join(File.dirname(__FILE__), 'spec_helper')

describe Weary do
  it 'makes a request' do
    r = Weary.request('http://google.com')
    r.class.should == Weary::Request
    r.uri.to_s.should == 'http://google.com'
    r.via.should == :get
  end
  
  it 'can alter the request' do
    block = lambda{|r| r.via = 'POST' }
    r = Weary.request('http://google.com', :get, block)
    r.via.should == :post
  end
  
  it 'makes a GET request' do
    r = Weary.get 'http://google.com'
    r.class.should == Weary::Request
    r.uri.to_s.should == 'http://google.com'
    r.via.should == :get
  end
    
  it 'makes a POST request' do
    r = Weary.post 'http://google.com'
    r.via.should == :post
  end
  
  it 'makes a PUT request' do
    r = Weary.put 'http://google.com'
    r.via.should == :put
  end
  
  it 'makes a DELETE request' do
    r = Weary.delete 'http://google.com'
    r.via.should == :delete
  end
  
  it 'makes a HEAD request' do
    r = Weary.head 'http://google.com'
    r.via.should == :head
  end
  
  it 'makes requests with an optional block' do
    r = Weary.get 'http://google.com' do |req| 
      req.with = {:id => 'markwunsch'} 
    end
    r.uri.query.should == r.with
  end
  
  describe 'Module' do
    before do
      klass = Class.new
      klass.instance_eval { include Weary }
      @test = klass.new
    end
    
    it 'can make a requst' do
      r = @test.request('http://google.com')
      r.class.should == Weary::Request
      r.uri.to_s.should == 'http://google.com'
      r.via.should == :get
    end
    
    it 'can alter the request' do
      block = lambda{|r| r.via = 'POST' }
      r = @test.request('http://google.com', :get, block)
      r.via.should == :post
    end

    it 'makes a GET request' do
      r = @test.get 'http://google.com'
      r.class.should == Weary::Request
      r.uri.to_s.should == 'http://google.com'
      r.via.should == :get
    end

    it 'makes a POST request' do
      r = @test.post 'http://google.com'
      r.via.should == :post
    end

    it 'makes a PUT request' do
      r = @test.put 'http://google.com'
      r.via.should == :put
    end

    it 'makes a DELETE request' do
      r = @test.delete 'http://google.com'
      r.via.should == :delete
    end

    it 'makes a HEAD request' do
      r = @test.head 'http://google.com'
      r.via.should == :head
    end

    it 'makes requests with an optional block' do
      r = @test.get 'http://google.com' do |req| 
        req.with = {:id => 'markwunsch'} 
      end
      r.uri.query.should == r.with
    end
  end
end