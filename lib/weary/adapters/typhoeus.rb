require 'typhoeus'

module Weary
  module Adapter
    class Typhoeus
      include Weary::Adapter

      def self.call(env)
        connect(Rack::Request.new(env)).finish
      end

      def call(env)
        self.class.call(env)
      end

      def self.connect(rack_request)
        response = ::Typhoeus::Request.run(url_for(rack_request), parameters_for(rack_request))
        Rack::Response.new response.body, response.code, response.headers_hash
      end

      def self.url_for(request)
        host = request.env['HTTP_HOST'] || request.env['SERVER_NAME']
        port = request.env['SERVER_PORT'].to_s
        if port == "80" || port == "443"
          "#{request.scheme}://#{host}#{request.fullpath}"
        else
          "#{request.scheme}://#{host}:#{port}#{request.fullpath}"
        end
      end

      def self.parameters_for(request)
        {
          :headers => normalize_request_headers(request.env),
          :method  => request.request_method.downcase.to_sym
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

      private

      UNWANTED_REQUEST_HEADERS = []

    end
  end
end