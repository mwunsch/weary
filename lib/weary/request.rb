require 'addressable/uri'
require 'thread' unless defined? ::Mutex # Ruby 1.8.7 support for promises
require 'future'
require 'rack'

require 'weary/requestable'
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
    include Weary::Requestable

    attr_reader :uri

    def initialize(url, method='GET')
      self.uri = url
      self.method = method
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
      middlewares = @middlewares || []
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
      body stringio_encode(json)
      json
    end

    def body(io=nil)
      @attachment = io unless io.nil?
      @attachment ||= stringio_encode("")
    end

    def basic_auth(*credentials)
      if !credentials.empty?
        @basic_auth = true
        use Weary::Middleware::BasicAuth, credentials
      end
      @basic_auth
    end

    def oauth(consumer_key=nil, access_token=nil, token_secret=nil, consumer_secret=nil)
      if !consumer_key.nil?
        @oauth = true
        options = {:consumer_key => consumer_key}
        options[:token] = access_token unless access_token.nil? || access_token.empty?
        options[:token_secret] = token_secret unless token_secret.nil? || token_secret.empty?
        options[:consumer_secret] = consumer_secret unless consumer_secret.nil? || consumer_secret.empty?
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

    private

    # Stolen from Faraday
    def query_params_from_hash(value, prefix = nil)
      case value
      when Array
        value.map { |v| query_params_from_hash(v, "#{prefix}%5B%5D") }.join("&")
      when Hash
        value.map { |k, v|
          query_params_from_hash(v, prefix ? "#{prefix}%5B#{Rack::Utils.escape_path(k)}%5D" : Rack::Utils.escape_path(k))
        }.join("&")
      when NilClass
        prefix
      else
        raise ArgumentError, "value must be a Hash" if prefix.nil?
        "#{prefix}=#{Rack::Utils.escape_path(value)}"
      end
    end

    def rack_env_defaults
      { 'rack.version'      => Rack::VERSION,
        'rack.errors'       => $stderr,
        'rack.multithread'  => true,
        'rack.multiprocess' => false,
        'rack.run_once'     => false }
    end

    def stringio_encode(content)
      io = StringIO.new(content)
      io.binmode
      io.set_encoding "ASCII-8BIT" if io.respond_to? :set_encoding
      io
    end

  end
end