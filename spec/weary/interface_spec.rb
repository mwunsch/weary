require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Weary::Interface do
  describe 'Class' do
    
    describe 'Resource Defaults' do
      before do
        @headers = {"User-Agent" => Weary::UserAgents["Safari 4.0.2 - Mac"]}
      end
      
      it 'sets default headers' do
        test = Class.new(Weary::Interface)
        test.headers @headers
        test.instance_variable_get(:@headers).should == @headers
      end
      
      it "sets a domain to be used in default url's" do
        test = Class.new(Weary::Interface)
        test.domain 'http://github.com'
        test.instance_variable_get(:@domain).should == 'http://github.com/'
      end
      
      it 'panics when a domain that is not a url is given' do
        test = Class.new(Weary::Interface)
        lambda { test.domain 'foobar' }.should raise_error
      end
      
      it "sets a format to use in default url's" do
        test = Class.new(Weary::Interface)
        test.format(:json)
        test.instance_variable_get(:@format).should == :json
      end
    end
    
    describe 'Resource Preparation' do
      before do
        @headers = {"User-Agent" => Weary::UserAgents["Safari 4.0.2 - Mac"]}
        prepTest = Class.new(Weary::Interface)
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
        t = Class.new(Weary::Interface)
        t.domain 'http://foobar.com'
        p = t.prepare_resource("test",:get)
        p.url.normalize.to_s.should == 'http://foobar.com/test.json'
      end
      
      it 'ignores the url if no domain is provided' do
        t = Class.new(Weary::Interface).prepare_resource("test",:get)
        t.url.should == nil        
      end
      
      it 'builds a default url following a pattern if a pattern is provided'  
      
      it 'ignores headers if no headers are defined' do
        t = Class.new(Weary::Interface).prepare_resource("test",:get)
        t.headers.should == nil
      end
    end
    
    describe 'Resource Storage' do
      before do
        @headers = {"User-Agent" => Weary::UserAgents["Safari 4.0.2 - Mac"]}
        @restest = Class.new(Weary::Interface)
        @restest.headers @headers
        @restest.domain 'http://foobar.com'
        @r = @restest.prepare_resource("test",:get)
      end
      
      it 'has a store for resources' do
        @restest.class_variable_defined?(:@@resources).should == true
      end
      
      it 'stores the resource for future use' do
        @restest.store_resource(@r).should == @r
        @restest.resources.include?(:test).should == true
      end      
    end
    
    describe 'Resource Construction' do
      before do
        @contest = Class.new(Weary::Interface)
        @contest.domain 'http://foobar.com'
      end
      
      it 'prepares a resource to be used' do
        r = @contest.build_resource "test", :post
        r.name.should == "test"
        r.via.should == :post
      end
      
      it 'passes the resource into a block for further refinement' do
        r = @contest.build_resource("test", :post, Proc.new {|res| res.via = :put })
        r.name.should == "test"
        r.via.should == :put
      end
      
      it 'stores the resource' do
        r = @contest.build_resource("test 2", :get)
        @contest.resources.include?(:test_2).should == true
      end
      
      it 'builds the method for the resource' do
        r = @contest.build_resource("test 3", :get)
        @contest.public_method_defined?(:test_3).should == true
      end
    end
    
    describe 'Resource Declaration' do
      before do
        @dectest = Class.new(Weary::Interface)
        @dectest.domain 'http://foobar.com'
      end
      
      it 'gets a resource' do
        r = @dectest.get "get test"
        r.via.should == :get
        r.name.should == "get_test"
      end
      
      it 'posts a resource' do
        r = @dectest.post "post test"
        r.via.should == :post
        r.name.should == "post_test"
      end
      
      it 'puts a resource' do
        r = @dectest.put "put test"
        r.via.should == :put
        r.name.should == "put_test"
      end
      
      it 'deletes a resource' do
        r = @dectest.delete "del test"
        r.via.should == :delete
        r.name.should == "del_test"
      end
      
      it 'declares a resource' do
        r = @dectest.declare "generic test"
        r.via.should == :get
        r.name.should == "generic_test"
      end
      
      it 'stores the resource' do
        @dectest.get "storage test"
        @dectest.resources.include?(:storage_test).should == true
      end
    end
    
    describe 'Method Building' do
      before do
        @methtest = Class.new(Weary::Interface)
        @methtest.domain 'http://foobar.com'
        
        r = @methtest.prepare_resource("method_test",:get)
        @methtest.build_method(r)
        
        a = @methtest.prepare_resource("authentication_test",:post)
        a.authenticates = true
        @methtest.build_method(a)
        
        d = @methtest.prepare_resource("params_test",:post)
        d.requires = :id
        d.with = [:message, :user]
        @methtest.build_method(d)
      end
      
      it 'builds a method with the name of the resource' do
        n = @methtest.new
        n.respond_to?(:method_test).should == true
      end
      
      it 'forms a Request according to the guidelines of the Resource' do
        n = @methtest.new
        n.method_test.class.should == Weary::Request
      end
      
      it 'passes in authentication credentials if defined' do
        n = @methtest.new
        cred = {:username => 'mwunsch', :password => 'secret'}
        lambda { n.authentication_test }.should raise_error
        n.credentials cred[:username], cred[:password]
        n.authentication_test.options[:basic_auth].should == cred
      end
      
      it 'passes in default parameters if defined' do
        n = @methtest.new
        defaults = {:id => 1234, :message => "Hello world"}
        lambda { n.params_test }.should raise_error
        n.defaults = defaults
        n.params_test.options[:body].should == defaults
      end
      
      it 'accepts parameters when given' do
        n = @methtest.new
        req = n.params_test :id => 1234, :message => "Hello world", :foo => "Bar"
        req.options[:body].should == {:id => 1234, :message => "Hello world"}
        req.options[:body].has_key?(:foo).should == false
      end
      
      
    end
    
  end
  
  describe 'Object' do
    before do
      @klass = Class.new(Weary::Interface)
      @klass.domain 'http://foobar.com'
      @klass.format :xml
      @klass.headers({"User-Agent" => Weary::UserAgents["Safari 4.0.2 - Mac"]})
      @klass.get "thing" do |r|
        r.requires = :id
        r.with = [:message, :user]
      end
      @klass.post "important" do |r|
        r.requires = :id
        r.authenticates = true
      end
    end
    
    it 'has methods defined by the class' do
      obj = @klass.new
      obj.respond_to?(:thing).should == true
      obj.respond_to?(:important).should == true
    end
    
    it 'can set authentication credentials' do
      obj = @klass.new
      
      obj.credentials "username", "password"
      obj.instance_variable_get(:@credentials).should == {:username => "username", :password => "password"}
      obj.important(:id => 1234).options[:basic_auth].should == obj.instance_variable_get(:@credentials)
    end
    
    it 'credentials can be an OAuth access token' do
      oauth_consumer = OAuth::Consumer.new("consumer_token","consumer_secret",{:site => 'http://foo.bar'})
      oauth_token = OAuth::AccessToken.new(oauth_consumer, "token", "secret")
      obj = @klass.new
      
      obj.credentials oauth_token
      obj.instance_variable_get(:@credentials).class.should == OAuth::AccessToken
      obj.important(:id => 1234).options.has_key?(:oauth).should == true
      obj.important(:id => 1234).options.has_key?(:basic_auth).should == false
    end
    
    it 'can set defaults to pass into requests' do
      obj = @klass.new
      
      obj.defaults = {:user => "mwunsch", :message => "hello world"}
      obj.defaults.should == {:user => "mwunsch", :message => "hello world"}
      obj.thing(:id => 1234).options[:query].should == {:user => "mwunsch", :message => "hello world", :id => 1234}
    end
    
    it 'has a list of resources' do
      obj = @klass.new
      
      obj.resources.count.should == @klass.resources.count
    end
    
    it 'should keep its resources separate' do
      obj = @klass.new
      
      obj.resources[:foo] = 'bar'
      obj.resources.has_key?(:foo).should == true
      @klass.resources.has_key?(:foo).should == false
      obj.resources.delete(:foo)
    end
    
    it 'is able to rebuild its request method, like a singleton' do
      obj1 = @klass.new
      require 'pp'
      
      obj1.resources[:thing].follows = false
      obj1.rebuild_method(obj1.resources[:thing])
      
      obj1.thing(:id => 1234).options[:no_follow].should == true
      @klass.new.thing(:id => 1234).options[:no_follow].should == nil
    end
    
    it 'can modify a resource without modifying the resources of its class' do
      obj = @klass.new
      
      obj.modify_resource(:thing) {|r| r.url = "http://bar.foo" }
      obj.resources[:thing].url.normalize.to_s.should == "http://bar.foo/"
      obj.class.resources[:thing].url.normalize.to_s.should_not == "http://bar.foo/"
    end
    
    it 'modifying a resource rebuilds the method' do
      obj = @klass.new
      
      obj.credentials "username", "password"
      obj.modify_resource(:important) {|r| r.follows = false }
      obj.important(:id => 1234).options[:no_follow].should == true
    end
    
  end
end