module Weary
  module Middleware
    class BasicAuth
      AUTH_HEADER = "HTTP_AUTHORIZATION"

      def initialize(app, *credentials)
        @app = app
        @auth = [credentials.join(':')].pack('m*')
      end

      def call(env)
        env.update AUTH_HEADER => "Basic #{@auth}"
        @app.call(env)
      end
    end
  end
end