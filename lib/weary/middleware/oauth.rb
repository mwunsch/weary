require 'weary/middleware'
require 'simple_oauth'

module Weary
  module Middleware
    class OAuth
      AUTH_HEADER = "HTTP_AUTHORIZATION"

      def initialize(app, oauth_options)
        @app = app
        @oauth = oauth_options
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