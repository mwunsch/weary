require 'weary/middleware'
require 'simple_oauth'

module Weary
  module Middleware
    class OAuth
      AUTH_HEADER = "HTTP_AUTHORIZATION"

      def initialize(app, consumer_key, access_token)
        @app = app
        @oauth = {
          :consumer_key => consumer_key
        }
        @oauth[:token] = access_token if access_token
      end

      def call(env)
        env.update AUTH_HEADER => sign(env).to_s
        @app.call(env)
      end

      def sign(env)
        req = Rack::Request.new(env)
        SimpleOAuth::Header.new req.request_method,
                                req.url,
                                req.params,
                                @oauth
      end
    end
  end
end