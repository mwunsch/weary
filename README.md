# Weary

_The Weary need REST_

Weary is a tiny DSL for making the consumption of RESTful web services simple. It is the little brother to [HTTParty](http://github.com/jnunemaker/httparty/ "JNunemaker's HTTParty"). It provides a thin, gossamer-like layer over the Net/HTTP library.

The things it do:

+ Quickly build an interface to your favorite REST API.
+ Parse XML and JSON with the [Crack](http://github.com/jnunemaker/crack) library.
+ Authenticate, basically, with Basic Authentication.
+ Consume with [OAuth](http://oauth.net/)

Browse the documentation here: [http://rdoc.info/projects/mwunsch/weary](http://rdoc.info/projects/mwunsch/weary)
Peruse the [Wiki](http://wiki.github.com/mwunsch/weary) to discover libraries built with Weary and a more thorough review of the API.

## Requirements

+ [Crack](http://github.com/jnunemaker/crack) >= 0.1.2
+ [Nokogiri](http://github.com/tenderlove/nokogiri) >= 1.3.1 (if you want to use the #search method)
+ [OAuth](http://github.com/mojodna/oauth) >= 0.3.5 (if you want to use OAuth)
+ [RSpec](http://rspec.info/) (for running the tests)

## Installation

You do have Rubygems right? You do use [Gemcutter](http://gemcutter.org/), right?

	sudo gem install weary
	
## Quick Start
	
	# http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-users%C2%A0show
	class TwitterUser
		extend Weary
		
		domain "http://twitter.com/users/"
		
		get "show" do |resource|
			resource.with = [:id, :user_id, :screen_name]
		end
	end
	
	user = TwitterUser.new
	me = user.show(:id => "markwunsch")
	puts me["name"]
	
Hey, that's me!	
	

## How it works

Create a class and `extend Weary` to give it methods to craft a resource request:

	class Foo
		extend Weary
		
		declare "foo" do |resource|
			resource.url = "http://path/to/foo"
		end
	end
	
If you instantiate this class, you'll get an instance method named `foo` that crafts a GET request to "http://path/to/foo"

Besides the name of the resource, you can also give `declare_resource` a block like:

	declare "foo" do |r|
		r.url = "path/to/foo"
		r.via = :post 							# defaults to :get
		r.format = :xml 						# defaults to :json
		r.requires = [:id, :bar] 				# an array of params that the resource requires to be in the query/body
		r.with = [:blah]						# an array of params that you can optionally send to the resource
		r.authenticates = false					# does the method require basic authentication? defaults to false
		r.oauth = false							# does this resource use OAuth to authorize you? it's boolean
		r.access_token = nil					# if you're using OAuth, you should provide the user's access token.
		r.follows = false						# if this is set to false, the formed request will not follow redirects.
		r.headers = {'Accept' => 'text/html'}	# send custom headers. defaults to nil.
	end
					
So this would form a method:
	
	x = Foo.new
	x.foo(:id => "mwunsch", :bar => 123)
	
That method would return a Weary::Response object that you could then parse or examine.

### Parsing the Body

Once you make your request with the fancy method that Weary created for you, you can do stuff with what it returns...which could be a good reason you're using Weary in the first place. Let's look at the above example:

	x = Foo.new
	y = x.foo(:id => "mwunsch", :bar => 123).parse
	y["foos"]["user"]
	
Weary parses with Crack. If you have some XML or HTML and want to search it with XPath or CSS selectors, you can use Nokogiri magic:

	x = Foo.new
	y = x.foo(:id => "mwunsch", :bar => 123)
	y.search("foos > user")
	
If you try to #search a non-XMLesque document, Weary will just throw the selector away and use the #parse method.

### Shortcuts

Of course, you don't always have to use `declare`; that is a little too ambiguous. You can also use `get`, `post`, `delete`, etc. Those do the obvious.

The `#requires` and `#with` methods can either be arrays of symbols, or a comma delimited list of strings.

### Forming URLs

There are many ways to form URLs in Weary. You can define URLs for the entire class by typing:

	class Foo
		extend Weary
		
		domain "http://foo.bar/"
		url "<domain><resource>.<format>"
		format :xml
		
		get "show_users"
	end
	
The string `<domain><resource>.<format>` helps define a simple pattern for creating URLs. These will be filled in by your resource declaration. The above `get` declaration creates a url that looks like: *http://foo.bar/show_users.xml*
	
If you use the `<domain>` flag but don't define a domain, an exception will be raised.
	
### Weary DSL

You can create some defaults for all of our resources easily:

	class Foo
		extend Weary

		domain "http://foo.bar/"
		url "<domain><resource>.<format>"
		format :xml
		headers {'Accept' => 'text/html'}							# set headers
		authenticates "basic_username","basic_password"				# basic authentication
		with [:login, :token]										# params that should be sent with every request
		oauth OAuth::AccessToken.new(consumer, "token", "secret")	# an access token for OAuth
		
		post "update"	# uses the defaults defined above!			
	end
	
There's more to discover in the Wiki.	
