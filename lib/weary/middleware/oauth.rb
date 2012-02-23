require 'simple_oauth'

module Weary
  module Middleware
    class OAuth
      AUTH_HEADER = "HTTP_AUTHORIZATION"

      def initialize(app, consumer_key, access_token)
        @app = app
        @oauth = {
          :consumer_key => consumer_key,
          :token => access_token
        }
      end

      def call(env)
        env.update AUTH_HEADER => sign(env).to_s
        @app.call(env)
      end

      def sign(env)
        request_method = env["REQUEST_METHOD"]
        url = env["weary.request"].uri.to_s
        params = {}
        SimpleOAuth::Header.new request_method,
                                url,
                                params,
                                @oauth
      end
    end
  end
end