require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Weary::Interface do
  describe 'Class' do
    
    describe 'Resource Defaults' do
      before do
        @headers = {"User-Agent" => Weary::UserAgents["Safari 4.0.2 - Mac"]}
      end
      
      it 'sets default headers' do
        test = Weary::Interface.dup
        test.headers @headers
        test.instance_variable_get(:@headers).should == @headers
      end
      
      it "sets a domain to be used in default url's" do
        test = Weary::Interface.dup
        test.domain 'http://github.com'
        test.instance_variable_get(:@domain).should == 'http://github.com/'
      end
      
      it 'panics when a domain that is not a url is given' do
        test = Weary::Interface.dup
        lambda { test.domain 'foobar' }.should raise_error
      end
      
      it "sets a format to use in default url's" do
        test = Weary::Interface.dup
        test.format(:json)
        test.instance_variable_get(:@format).should == :json
      end
    end
    
    describe 'Resource Preparation' do
      before do
        @headers = {"User-Agent" => Weary::UserAgents["Safari 4.0.2 - Mac"]}
        prepTest = Weary::Interface.dup
        prepTest.headers @headers
        prepTest.domain 'http://foobar.com'
        prepTest.format :xml
        @t = prepTest.prepare_resource("test",:get)
      end
      
      it 'prepares a Resource' do
        @t.class.should == Weary::Resource
      end
      
      it 'has a name' do
        @t.name.should == "test"
      end
      
      it 'has an http method' do
        @t.via.should == :get
      end
      
      it 'has headers' do
        @t.headers.should == @headers
      end
      
      it 'builds a default url if a domain is provided' do
        @t.url.normalize.to_s.should == 'http://foobar.com/test.xml'
      end
      
      it 'builds a default url with a json extension if no format is explicitly named' do
        t = Weary::Interface.dup
        t.domain 'http://foobar.com'
        p = t.prepare_resource("test",:get)
        p.url.normalize.to_s.should == 'http://foobar.com/test.json'
      end
      
      it 'ignores the url if no domain is provided' do
        t = Weary::Interface.dup.prepare_resource("test",:get)
        t.url.should == nil        
      end
      
      it 'builds a default url following a pattern if a pattern is provided'  
      
      it 'ignores headers if no headers are defined' do
        t = Weary::Interface.dup.prepare_resource("test",:get)
        t.headers.should == nil
      end
    end
    
    describe 'Resource Storage' do
      before do
        @headers = {"User-Agent" => Weary::UserAgents["Safari 4.0.2 - Mac"]}
        @test = Weary::Interface.dup
        @test.headers @headers
        @test.domain 'http://foobar.com'
        @r = @test.prepare_resource("test",:get)
      end
      
      it 'has a store for resources' do
        @test.class_variable_defined?(:@@resources).should == true
      end
      
      it 'stores the resource for future use' do
        @test.store_resource(@r).should == @r
        @test.resources.include?(:test).should == true
      end      
    end
    
    describe 'Resource Construction' do
      before do
        @test = Weary::Interface.dup
        @test.domain 'http://foobar.com'
      end
      
      it 'prepares a resource to be used' do
        r = @test.build_resource "test", :post
        r.name.should == "test"
        r.via.should == :post
      end
      
      it 'passes the resource into a block for further refinement' do
        r = @test.build_resource("test", :post, Proc.new {|res| res.via = :put })
        r.name.should == "test"
        r.via.should == :put
      end
      
      it 'stores the resource' do
        r = @test.build_resource("test 2", :get)
        @test.resources.include?(:test_2).should == true
      end
    end
    
    describe 'Resource Declaration' do
      before do
        @test = Weary::Interface.dup
        @test.domain 'http://foobar.com'
      end
      
      it 'gets a resource' do
        r = @test.get "get test"
        r.via.should == :get
        r.name.should == "get_test"
      end
      
      it 'posts a resource' do
        r = @test.post "post test"
        r.via.should == :post
        r.name.should == "post_test"
      end
      
      it 'puts a resource' do
        r = @test.put "put test"
        r.via.should == :put
        r.name.should == "put_test"
      end
      
      it 'deletes a resource' do
        r = @test.delete "del test"
        r.via.should == :delete
        r.name.should == "del_test"
      end
      
      it 'declares a resource' do
        r = @test.declare "generic test"
        r.via.should == :get
        r.name.should == "generic_test"
      end
      
      it 'stores the resource' do
        @test.get "storage test"
        @test.resources.include?(:storage_test).should == true
      end
    end
    
    describe 'Method Building' do
      before do
        @test = Weary::Interface.dup
        @test.domain 'http://foobar.com'
        
        r = @test.prepare_resource("method_test",:get)
        @test.build_method(r)
        
        a = @test.prepare_resource("authentication_test",:post)
        a.authenticates = true
        @test.build_method(a)
        
        d = @test.prepare_resource("params_test",:post)
        d.requires = :id
        d.with = [:message, :user]
        @test.build_method(d)
      end
      
      it 'builds a method with the name of the resource' do
        n = @test.new
        n.respond_to?(:method_test).should == true
      end
      
      it 'forms a Request according to the guidelines of the Resource' do
        n = @test.new
        n.method_test.class.should == Weary::Request
      end
      
      it 'passes in authentication credentials if defined' do
        n = @test.new
        cred = {:username => 'mwunsch', :password => 'secret'}
        lambda { n.authentication_test }.should raise_error
        n.credentials = cred
        n.authentication_test.options[:basic_auth].should == cred
      end
      
      it 'passes in default parameters if defined' do
        n = @test.new
        defaults = {:id => 1234, :message => "Hello world"}
        lambda { n.params_test }.should raise_error
        n.defaults = defaults
        n.params_test.options[:body].should == defaults
      end
      
      it 'accepts parameters when given' do
        n = @test.new
        req = n.params_test :id => 1234, :message => "Hello world", :foo => "Bar"
        req.options[:body].should == {:id => 1234, :message => "Hello world"}
        req.options[:body].has_key?(:foo).should == false
      end
      
      
    end
    
  end
end