require 'net/http'
require 'net/https'

module Weary
  module Adapter
    class NetHttp
      include Weary::Adapter

      def self.call(env)
        connect(Rack::Request.new(env)).finish
      end

      def self.connect(request)
        connection = socket(request)
        response = connection.send_request(request.request_method,
                                           request.fullpath,
                                           nil,
                                           normalize_request_headers(request.env))
        Rack::Response.new response.body, response.code, response.to_hash
      end

      def self.normalize_request_headers(env)
        req_headers = env.reject {|k,v| !k.start_with? "HTTP_" }
        normalized = req_headers.map do |k, v|
          new_key = k.sub("HTTP_",'').split('_').map(&:capitalize).join('-')
          [new_key, v]
        end
        Hash[normalized]
      end

      def self.socket(request)
        host = request.env['SERVER_NAME']
        port = request.env['SERVER_PORT'].to_s
        connection = Net::HTTP.new host, port
        connection.use_ssl = request.scheme.eql?'https'
        connection.verify_mode = OpenSSL::SSL::VERIFY_NONE if connection.use_ssl?
        connection
      end

      def call(env)
        self.class.call(env)
      end

    end
  end
end