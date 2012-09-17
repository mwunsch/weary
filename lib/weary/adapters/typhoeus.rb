require 'typhoeus'

module Weary
  module Adapter
    class Typhoeus

      class << self
        include Weary::Adapter

        def connect(rack_request)
          response = ::Typhoeus::Request.run(url_for(rack_request), parameters_for(rack_request))
          Rack::Response.new response.body, response.code, response.headers_hash
        end

        def url_for(request)
          host = request.env['HTTP_HOST'] || request.env['SERVER_NAME']
          port = request.env['SERVER_PORT'].to_s
          if port == "80" || port == "443"
            "#{request.scheme}://#{host}#{request.fullpath}"
          else
            "#{request.scheme}://#{host}:#{port}#{request.fullpath}"
          end
        end

        def parameters_for(request)
          {
            :headers => normalize_request_headers(request.env),
            :method  => request.request_method.downcase.to_sym
          }.merge(if request.request_method.upcase == "GET"
            { :query => request.params }
          else
            { :body => request.params.map { |k,v| "#{k}=#{v}" }.join("&") }
          end)
        end
      end

      include Weary::Adapter

      def connect(rack_request)
        self.class.connect(rack_request)
      end

    end
  end
end