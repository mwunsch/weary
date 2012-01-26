require 'net/http'

module Weary
  module Adapter
    class NetHttp
      include Weary::Adapter

      def self.call(env)
        perform(env).finish
      end

      def self.perform(env)
        req = Rack::Request.new(env)
        response = connect(req)
        yield response if block_given?
        response
      end

      def self.connect(request)
         response = socket(request).send_request(request.request_method, request.path)
         Rack::Response.new response.body, response.code, headers(response)
      end

      def self.socket(request)
        host = request.env['SERVER_NAME']
        port = request.env['SERVER_PORT'].to_s
        Net::HTTP.new host, port
      end

      def self.headers(response)
        map = {}
        response.each_capitalized do |key, value|
          map[key] = value unless key == 'Status' # Pass Rack::Lint assertions
        end
        map
      end

      def call(env)
        self.class.call(env)
      end

      def perform(env, &block)
        self.class.perform(env, &block)
      end

    end
  end
end