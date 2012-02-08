require 'simple_oauth'

module Weary
  module Middleware
    class OAuth
      def initialize(app)
        @app = app
      end

      def call(env)
        # env.update
        @app.call(env)
      end
    end
  end
end