require 'excon'

module Weary
  module Adapter
    class Excon
      include Weary::Adapter

      def self.call(env)
        connect(Rack::Request.new(env)).finish
      end

      def self.connect(request)
        connection = ::Excon.new(host_and_port_for_request(request))
        response = connection.request prepare(request)
        Rack::Response.new response.body, response.status, normalize_response_headers(response.headers)
      end

      def self.host_and_port_for_request(request)
        host = request.env['HTTP_HOST'] || request.env['SERVER_NAME']
        port = request.env['SERVER_PORT'].to_s
        if port == "80" || port == "443"
          "#{request.scheme}://#{host}"
        else
          "#{request.scheme}://#{host}:#{port}"
        end
      end

      def self.prepare(request)
        {
          :headers => normalize_request_headers(request.env),
          :method  => request.request_method,
          :path    => request.fullpath
        }.merge(if request.request_method.upcase == "GET"
          { :query => request.params }
        else
          { :body => request.params.map { |k,v| "#{k}=#{v}" }.join("&") }
        end)
      end

      def self.normalize_request_headers(env)
        req_headers = env.reject {|k,v| !k.start_with? "HTTP_" }
        normalized = req_headers.map do |k, v|
          new_key = k.sub("HTTP_",'').split('_').map(&:capitalize).join('-')
          [new_key, v] unless UNWANTED_REQUEST_HEADERS.include? new_key
        end
        Hash[normalized]
      end

      def self.normalize_response_headers(headers)
        headers.reject { |k,v| k.downcase == 'status' }
      end

      def call(env)
        self.class.call(env)
      end

      private

      UNWANTED_REQUEST_HEADERS = []

    end
  end
end