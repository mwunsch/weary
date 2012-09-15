require 'timeout'

module Weary
  module Middleware
    class Timeout

      def initialize(app, time = 15)
        @app = app
        @time = time
      end

      def call(env)
        begin
          ::Timeout.timeout(@time) { @app.call(env) }
        rescue ::Timeout::Error => e
          [504, {'Content-Type' => "text/plain"}, [e.message]]
        end
      end

    end
  end
end