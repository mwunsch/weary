# Weary

_The Weary need REST_

Weary is a tiny DSL for making the consumption of RESTful web services simple. It is the little brother to [HTTParty](http://github.com/jnunemaker/httparty/ "JNunemaker's HTTParty"). It provides a thin, gossamer-like layer over the Net/HTTP library.

The things it do:

+ Quickly build an interface to your favorite REST API.
+ Parse XML and JSON with the [Crack](http://github.com/jnunemaker/crack) library.

Browse the documentation here: [http://rdoc.info/projects/mwunsch/weary](http://rdoc.info/projects/mwunsch/weary)

## Requirements

+ Crack >= 0.1.2
+ Nokogiri >= 1.3.1 (if you want to use the #search method)

## Installation

You do have Rubygems right?

	sudo gem install weary

## How it works

Create a class and `extend Weary` to give it methods to craft a resource request:

	class Foo
		extend Weary
		
		declare_resource "foo",
						 :url => "http://path/to/foo"
	end
	
If you instantiate this class, you'll get an instance method named `foo` that crafts a GET request to "http://path/to/foo"

Besides the name of the resource, you can also give `declare_resource` a hash of options like:

	declare_resource "foo",
					 :url => "path/to/foo",
					 :via => :post, 			# defaults to :get
					 :format => :xml, 			# defaults to :json
					 :requires => [:id, :bar], 	# an array of params that the resource requires to be in the query/body
					 :with => [:blah],			# an array of params that you can optionally send to the resource
					 :authenticates => false,	# does the method require basic authentication? defaults to false
					 :no_follow => true			# if this is set to true, the formed request will not follow redirects
					
So this would form a method:
	
	x = Foo.new
	x.foo(:id => "mwunsch", :bar => 123)
	
That method would return a Weary::Response object that you could then parse or examine.