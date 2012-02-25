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
        env.update CONTENT_TYPE => @type
        env.update CONTENT_LENGTH => length(env['rack.input'])
        @app.call(env)
      end

      def length(input)
        input.size.to_s
      end
    end
  end
end