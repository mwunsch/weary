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
        response = connection.request prepare(request)
        Rack::Response.new response.body || "", response.code, normalize_response(response.to_hash)
      end

      def self.prepare(request)
        req_class = request_class(request.request_method)
        net_http_req = req_class.new(request.fullpath, normalize_request_headers(request.env))
        if net_http_req.request_body_permitted? # What's the best way of passing the body?
          net_http_req.body = request.body.read
          request.body.rewind
        end
        net_http_req.content_type = request.content_type if request.content_type
        net_http_req.content_length = request.content_length if request.content_length
        net_http_req
      end

      def self.normalize_request_headers(env)
        req_headers = env.reject {|k,v| !k.start_with? "HTTP_" }
        normalized = req_headers.map do |k, v|
          new_key = k.sub("HTTP_",'').split('_').map(&:capitalize).join('-')
          [new_key, v] unless UNWANTED_REQUEST_HEADERS.include? new_key
        end
        Hash[normalized]
      end

      def self.normalize_response(headers)
        headers.reject {|k,v| k.downcase == 'status' }
      end

      def self.socket(request)
        host = request.env['HTTP_HOST'] || request.env['SERVER_NAME']
        port = request.env['SERVER_PORT'].to_s
        connection = Net::HTTP.new host, port
        connection.use_ssl = request.scheme == 'https'
        connection.verify_mode = OpenSSL::SSL::VERIFY_NONE if connection.use_ssl?
        connection
      end

      def self.request_class(method)
        capitalized = method.capitalize
        Net::HTTP.const_get capitalized
      end

      def call(env)
        self.class.call(env)
      end

      private

      UNWANTED_REQUEST_HEADERS = []

    end
  end
end