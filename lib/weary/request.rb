# A Request builds a rack env to hand off to an adapter,
# which is a rack application that actually makes the request
require 'addressable/uri'
require 'future'
require 'rack'

require 'weary/env'
require 'weary/adapter'

autoload :Middleware, 'weary/middleware'
autoload :MultiJson, 'multi_json'

module Weary
  class Request
    attr_reader :uri

    def initialize(url, method='GET')
      self.uri = url
      self.method = method
      @middlewares = []
      yield self if block_given?
    end

    def uri=(url)
      uri = Addressable::URI.parse(url).normalize!
      @uri = uri
    end

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

    def env
      Weary::Env.new(self).env
    end

    def method
      @method
    end

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
      @connection ||= Weary::Adapter::NetHttp
    end

    def basic_auth(*credentials)
      if !credentials.empty?
        @basic_auth = true
        use Weary::Middleware::BasicAuth, credentials
      end
      @basic_auth
    end

    def oauth(consumer_key=nil, access_token=nil)
      if !consumer_key.nil? && !access_token.nil?
        @oauth = true
        use Weary::Middleware::OAuth, [consumer_key, access_token]
      end
      @oauth
    end

    # A Future comes back
    def perform
      future do
        status, headers, body = call(rack_env_defaults)
        response = Weary::Response.new body, status, headers
        yield response if block_given?
        response
      end
    end

    def use(middleware, *args, &block)
      @middlewares << [middleware, args, block]
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