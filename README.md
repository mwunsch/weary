# Weary

[![Build Status](https://secure.travis-ci.org/mwunsch/weary.png)](http://travis-ci.org/mwunsch/weary) [![Code Climate](https://codeclimate.com/github/mwunsch/weary.png)](https://codeclimate.com/github/mwunsch/weary)

_Weary is a framework and DSL for building clients for (preferably RESTful) web service APIs._

At its most minimal, Weary is simply some nice syntactic sugar around Net/HTTP.

If you dig a bit deeper, it's a suite of tools built around the [Rack](http://rack.rubyforge.org/) ecosystem. As you build a client, remember that just about every class in Weary is a piece of Rack middleware or a Rack application underneath the covers.

It features:

*   Full Rack integration:

    There are points in the stack to hook in Rack middleware and just about every class in Weary is a Rack application in its own right.

*   Asynchronous:

    `Weary::Request#perform`, the thing that performs the request, returns a [future](http://en.wikipedia.org/wiki/Futures_and_promises) and only blocks when accessed.

It takes its inspiration from [HTTParty](https://github.com/jnunemaker/httparty) and [Faraday](https://github.com/technoweenie/faraday).

## Quick Start

```ruby
# http://developer.github.com/v3/repos/
class GithubRepo < Weary::Client
  domain "https://api.github.com"

  use Rack::Lint

  get :list_user_repos, "/users/{user}/repos" do |resource|
    resource.optional :type
  end

  get :get, "/repos/{user}/{repo}"
end

client = GithubRepo.new
client.list_user_repos(:user => "mwunsch").perform do |response|
  puts response.body if response.success?
end
```

This is a basic example of a client you will build using the Weary framework. If you're coming from a previous version of Weary, you would have created a subclass of `Weary::Base`. That's one of the many changes in the **big rewrite**.

### Weary::Client

Inherit from `Weary::Client` for a set of class methods that craft "Resources" (more on that later).

```ruby
class MyClass < Weary::Client
  get :resource, "http://host.com/path/to/resource" do |resource|
    resource.optional :optional_parameter
  end
end
```

The DSL provides methods for all of the HTTP verbs (See `Weary::Client::REQUEST_METHODS`). When you instantiate this class, the object will have an instance method named "resource" that will return a `Weary::Request` object set up to perform a "GET" request on "http://host.com/path/to/resource".

You can pass a block to these methods for access to the `Weary::Resource`.

Further methods in the DSL include:

    domain   - This will be prepended to every path when resources are defined
                 (Particularly useful when using Client's Rack integration, discussed below).
    optional - See Resource section below.
    required - See Resource section below.
    defaults - See Resource section below.
    headers  - See Resource section below.
    use      - A Rack::Middleware to place in the Request stack.
                 (See Rack integration further down)


#### Weary::Resource

The resource is a building block used in `Client` to describe the requirements of a request.

    optional    - A group of keys for parameters that the request expects.
    required    - Keys that the request needs in order to be performed.
    defaults    - Default parameters to be sent in every request.
    headers     - Headers to send in the request.
    user_agent  - A convenience method to set the User Agent header.
    basic_auth! - Prepare the request to accept a username and password for basic authentication.
    oauth!      - Prepare the request to accept the consumer key and access token in the request.

Finally, the `request` method of the Resource takes a set of parameters to verify that requirements are met and returns a `Weary::Request` object. It should all look something like this once all is said and done.

```ruby
# https://dev.twitter.com/docs/api/1/post/statuses/update
post :update, "http://api.twitter.com/1/statuses/update.json" do |resource|
  resource.required :status
  resource.optional :in_reply_to_status_id, :lat, :long, :place_id,
                    :display_coordinates, :trim_user, :include_entities
  resource.oauth!
end

# After instantiating the client:
# (This calls the "update" resource's `request` method)
client.update :status       => "I'm tweeting from Weary",
              :consumer_key => "an_oauth_consumer_key",
              :token        => "my_oauth_access_token"

```

If a `required` parameter is missing, a `Weary::Resource::UnmetRequirementsError` exception is raised.

URL's for these methods can also be dynamic. If we alter the above example:

    post :update, "http://api.twitter.com/1/statuses/update.{format}" do |resource|

Then a key `:format` will be expected to be passed with the other parameters.

The method that the Client defines (in the above example, the `client.update` method), can take an optional block that allows you to manipulate the underlying `Weary::Request` object.

### Weary::Request

No matter how you get there, you'll end up with a Weary::Request object. Call the `perform` method to actually make the request and get back a `Weary::Response`. That's not entirely true... `Weary::Request#perform` is asynchronous and non-blocking. It returns a future and will only block once you call a method on the response. You can optionally pass a block that's executed once the response has returned.

By default, the request is performed through [Net::HTTP](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/net/http/rdoc/Net/HTTP.html). This is done through `Weary::Adapter::NetHttp`. A `Weary::Adapter` is just a special kind of Rack application. `Request#adapter` allows you to hook up your own. Weary also includes adapters for [Typhoeus](http://typhoeus.github.com/) and [Excon](https://github.com/geemus/excon).

#### Requestable

`Client`, `Resource`, and `Request` include a Module named `Requestable`. Using this module, it's easy to cascade certain pieces of configuration down from the stack.

For example, you can call `Client#adapter` to change the adapter for all of the resources of that client. Or you can call `Resource#adapter` to change the adapter for requests built for that resource. OR you can call `Request#adapter` to change the adapter for just that request.

## Rack

To maximize the utility of Weary, it's important to remember that driving everything is Rack. Almost every class is built to provide a Rack interface.

Every class that inherits from `Weary::Client` is a Rack application.

A `Weary::Request` is a Rack application. When you call `Request#call` it creates its own special Rack environment. In order to preserve your Rack middleware, you can add your middleware to the stack using `Request#use`.

When using `Weary::Client` the `use` method will add the passed middleware to every Request stack.

Authentication, by default is done by either `Weary::Middleware::BasicAuth` or `Weary::Middleware::OAuth`. Both are just Rack middleware, and can be used in any Rack stack.

The point is, **it's just Rack**.

## Weary needs your help.

At this point, I need _your_ help to further Weary along. I'd love to see more examples that utilize the Rackness of Weary: using Devise, Warden, or mounted in a Rails application.

## Examples

[**Gilt**](https://github.com/mwunsch/gilt) is a Ruby client to the [Gilt public API](https://dev.gilt.com/). Notice how much of the code is dedicated to the Gilt domain model, and very little to actually interacting with the web service. That's the idea.

## Copyright

Copyright (c) 2009 - 2013 Mark Wunsch. Licensed under the [MIT License](http://opensource.org/licenses/mit-license.php).
