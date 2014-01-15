module Weary
  module Middleware
    class ContentType

      CONTENT_TYPE = 'CONTENT_TYPE'
      CONTENT_LENGTH = 'CONTENT_LENGTH'
      FORM_URL_ENCODED = 'application/x-www-form-urlencoded'
      MULTIPART_FORM = 'multipart/form-data'

      attr_reader :type

      def initialize(app, type = FORM_URL_ENCODED)
        @app = app
        @type = type
      end

      def call(env)
        size = length(env['rack.input'])
        env.update CONTENT_TYPE => @type
        env.update CONTENT_LENGTH => size.to_s unless size.nil? or size.zero?
        @app.call(env)
      end

      def length(input)
        input.respond_to?(:size) ? input.size : 0
      end
    end
  end
end
