# Weary

Weary is a tiny DSL for making the consumption of RESTful web services simple. It has evolved from the ideas put forth by libraries like [HTTParty](http://github.com/jnunemaker/httparty/ "JNunemaker's HTTParty") and [Typhoeus](http://github.com/pauldix/typhoeus "Paul Dix's Typhoeus"). It provides some sweet syntactic sugar over the Net/HTTP standard library.

What does it do:

+ Quickly build an interface to your favorite REST API.
+ Parse XML and JSON with the [Crack](http://github.com/jnunemaker/crack) library.
+ Authentication with Basic Authentication and [OAuth](http://oauth.net/).
+ Asynchronous, multi-threaded requests.

Browse the documentation here: [http://rdoc.info/projects/mwunsch/weary](http://rdoc.info/projects/mwunsch/weary)
Peruse the [Wiki](http://wiki.github.com/mwunsch/weary) to discover libraries built with Weary and a more thorough review of the API.

## Requirements

+ [Crack](http://github.com/jnunemaker/crack) >= 0.1.2
+ [OAuth](http://github.com/mojodna/oauth) >= 0.3.5
+ [RSpec](http://rspec.info/) (for running the tests)
+ [FakeWeb](http://github.com/chrisk/fakeweb) (for running the tests)

## Installation

You do have Rubygems right? You do use [Gemcutter](http://gemcutter.org/), right?

	gem install weary
	
## Quick Start
	
	# http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-users%C2%A0show
	class TwitterUser < Weary::Base
		
		domain "http://twitter.com/users/"
		
		get "show" do |resource|
			resource.with = [:id, :user_id, :screen_name]
		end
	end
	
	user = TwitterUser.new
	me = user.show(:id => "markwunsch").perform
	puts me["name"]
	
Hey, that's me!

## The Base API/DSL

Create a class that inherits from `Weary::Base` to give it methods to craft a resource request:

	class Foo < Weary::Base
		
		declare "foo" do |resource|
			resource.url = "http://path/to/foo"
		end
	end
	
If you instantiate this class, you'll get an instance method named `foo` that crafts a GET request to "http://path/to/foo"

Besides the name of the resource, you can also give `declare` a block like:

	declare "foo" do |r|
		r.url = "path/to/foo"
		r.via = :post 							# defaults to :get
		r.requires = [:id, :bar] 				# an array of params that the resource requires to be in the query/body
		r.with = [:blah]						# an array of params that you can optionally send to the resource
		r.authenticates = false					# does the method require authentication? defaults to false
		r.follows = false						# if this is set to false, the formed request will not follow redirects.
		r.headers = {'Accept' => 'text/html'}	# send custom headers. defaults to nil.
	end
					
So this would form a method:
	
	x = Foo.new
	x.foo :id => "mwunsch", :bar => 123
	
That method would return a `Weary::Request` object. Use the `perform` method and get a `Weary::Response` that you could parse and/or examine.

### Parsing the Body

Once you make your request with the fancy method that Weary created for you, you can do stuff with what it returns...which could be a good reason you're using Weary in the first place. Let's look at the above example:

	x = Foo.new
	y = x.foo(:id => "mwunsch", :bar => 123).perform.parse
	y["foos"]["user"]
	
Weary parses with Crack, but you're not beholden to it. You can get the raw Request body to have your way with:

	x = Foo.new
	y = x.foo(:id => "mwunsch", :bar => 123).perform
	Nokogiri.parse(y.body)
	
*note: Weary used to have Nokogiri built in, using the `#search` method, but that was dropped.*	

### Shortcuts

Of course, you don't always have to use `declare`; that is a little too ambiguous. You can also use `get`, `post`, `delete`, etc. Those do the obvious.

### Forming URLs

There are many ways to form URLs in Weary. You can define URLs for the entire class by typing:

	class Foo < Weary::Base
		
		domain "http://foo.bar/"
		format :xml
		
		get "show_users"
	end
	
If you don't supply a url when declaring the Resource, Weary will look to see if you've defined a domain, and will make a url for you. The above `get` declaration creates a url that looks like: *http://foo.bar/show_users.xml*. I think it's better to write the whole URL out. That's unambiguous.
	
### Weary DSL

You can create some defaults for all of our resources easily:

	class Foo < Weary::Base
	
		def initialize(username,password)
			self.credentials username,password	#basic authentication
			self.defaults = {:user => username}	#parameters that will be passed in every request	 
		end

		domain "http://foo.bar/"
		format :xml
		headers {'Accept' => 'text/html'}	# set headers
		
		post "update" {|r| r.authenticates = true}	# uses the defaults defined above!			
	end
	
Then you can do something like this:

	f = Foo.new('me','secretz')
	f.update
	
Which will create a POST Request for *http://foo.bar/update.xml* that will authenticate you, using basic authentication, with the username/password of "me"/"secrets" and will send the parameter `{:user => "me"}`. Easy.

## Weary Class Methods

Maybe you don't want the baggage that comes with `Weary::Base`. That's okay, Weary provides some basic class-level methods to Easily build a `Weary::Requests`:

	# See examples/repo.rb to see this in practice
	class Repository

	  def show(user, repo)
	    Weary.get "http://github.com/api/v2/yaml/repos/show/#{user}/#{repo}"
	  end

	end
	
	Repository.new.show 'mwunsch', 'weary'
	
That will build the Get request to fetch the YAML info about this repository.

Pass a block to `Weary.get` to dive further into the Request:

	Weary.get "http://twitter.com/statuses/user_timeline" do |req|
		req.follows = false
		req.with = {:id => 'markwunsch'}
		req.credentials = {:username => 'markwunsch', :password => 'secret'}
		req.headers = {"User-Agent" => Weary::UserAgents["Safari 4.0.2 - Mac"]}
	end
	
## Request Callbacks

*Still to come*

## And more...	
	
There's more to discover in the Wiki.
