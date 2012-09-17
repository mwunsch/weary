require 'excon'

module Weary
  module Adapter
    class Excon

      class << self
        include Weary::Adapter

        def connect(request)
          connection = ::Excon.new(host_and_port_for_request(request))
          response = connection.request prepare(request)
          Rack::Response.new response.body, response.status, normalize_response(response.headers)
        end

        def host_and_port_for_request(request)
          host = request.env['HTTP_HOST'] || request.env['SERVER_NAME']
          port = request.env['SERVER_PORT'].to_s
          if port == "80" || port == "443"
            "#{request.scheme}://#{host}"
          else
            "#{request.scheme}://#{host}:#{port}"
          end
        end

        def prepare(request)
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
      end

      include Weary::Adapter

      def connect(rack_request)
        self.class.connect(rack_request)
      end

    end
  end
end