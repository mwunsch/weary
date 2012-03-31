require 'addressable/uri'
require 'future'
require 'rack'

require 'weary/env'
require 'weary/adapter'

module Weary
  autoload :Middleware, 'weary/middleware'
  autoload :MultiJson, 'multi_json'
  # A Request is an interface to an http request. It doesn't actually make the
  # request. Instead, it builds itself up into a Rack environment. A Request
  # object is technically a Rack middleware, with a call method. The Request
  # manipulates the passed in environment, then passes on to the adapter: A
  # Rack application. Because the Request performs so much manipulation on
  # the Rack env, you can attach middleware to it to act on its mutated env.
  class Request
    attr_reader :uri

    def initialize(url, method='GET')
      self.uri = url
      self.method = method
      @middlewares = []
      yield self if block_given?
    end

    # Set and normalize the url for the Request.
    def uri=(url)
      uri = Addressable::URI.parse(url).normalize!
      @uri = uri
    end

    # A Rack interface for the Request. Applies itself and whatever
    # middlewares to the env and passes the new env into the adapter.
    #
    # environment - A Hash for the Rack env.
    #
    # Returns an Array of three items; a Rack tuple.
    def call(environment)
      app = adapter.new
      middlewares = @middlewares
      stack = Rack::Builder.new do
        middlewares.each do |middleware|
          klass, *args = middleware
          use klass, *args[0...-1].flatten, &args.last
        end
        run app
      end
      stack.call rack_env_defaults.merge(environment.update(env))
    end

    # Build a Rack environment representing this Request.
    def env
      Weary::Env.new(self).env
    end

    # The HTTP request method for this Request.
    def method
      @method
    end

    # Set and normalize the HTTP request method.
    def method=(verb)
      @method = verb.to_s.upcase
    end

    def headers(hash=nil)
      @headers = hash unless hash.nil?
      @headers ||= {}
    end

    def user_agent(agent)
      headers.update 'User-Agent' => agent
    end

    def params(parameters=nil)
      if !parameters.nil?
        if ["POST", "PUT"].include? method
          @body = query_params_from_hash(parameters)
          body StringIO.new(@body)
          use Weary::Middleware::ContentType
        else
          uri.query_values = parameters
          @body = uri.query
        end
      end
      @body
    end

    def json(parameters)
      json = MultiJson.encode(parameters)
      body StringIO.new(json)
      json
    end

    def body(io=nil)
      @attachment = io unless io.nil?
      @attachment ||= StringIO.new('')
    end

    def adapter(connection=nil)
      @connection = connection unless connection.nil?
      @connection ||= Weary.adapter
    end

    def basic_auth(*credentials)
      if !credentials.empty?
        @basic_auth = true
        use Weary::Middleware::BasicAuth, credentials
      end
      @basic_auth
    end

    def oauth(consumer_key=nil, access_token=nil)
      if !consumer_key.nil?
        @oauth = true
        options = {:consumer_key => consumer_key}
        options[:token] = access_token unless access_token.nil? || access_token.empty?
        use Weary::Middleware::OAuth, [options]
      end
      @oauth
    end

    # Returns a future-wrapped Response.
    def perform
      future do
        status, headers, body = call(rack_env_defaults)
        response = Weary::Response.new body, status, headers
        yield response if block_given?
        response
      end
    end

    def use(middleware, *args, &block)
      @middlewares << [middleware, args.compact, block]
    end

    private

    def query_params_from_hash(hash)
      tmp_uri = Addressable::URI.new
      tmp_uri.query_values = hash
      tmp_uri.query
    end

    def rack_env_defaults
      { 'rack.version'      => Rack::VERSION,
        'rack.errors'       => $stderr,
        'rack.multithread'  => true,
        'rack.multiprocess' => false,
        'rack.run_once'     => false }
    end

  end
end