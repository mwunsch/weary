require 'excon'

module Weary
  module Adapter
    class Excon

      class << self
        include Weary::Adapter

        def connect(request)
          connection = ::Excon.new("#{request.scheme}://#{request.host_with_port}")
          response = connection.request prepare(request)
          Rack::Response.new response.body, response.status, normalize_response(response.headers)
        end

        def prepare(request)
          has_query = !(request.query_string.nil? || request.query_string.empty?)
          excon_params = { :headers => normalize_request_headers(request.env),
                           :method  => request.request_method,
                           :path    => request.path,
                           :body    => request.body.read }
          excon_params[:query] if has_query
          request.body.rewind
          excon_params
        end
      end

      include Weary::Adapter

      def connect(rack_request)
        self.class.connect(rack_request)
      end

    end
  end
end