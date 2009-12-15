require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Weary::Batch do
  it 'is a group of requests' do
    requests = [ Weary::Request.new('http://twitter.com'),
                 Weary::Request.new('http://github.com'),
                 Weary::Request.new('http://vimeo.com'),
                 Weary::Request.new('http://tumblr.com')]
    
    test = Weary::Batch.new(requests)
    test.requests.should == requests
  end
end