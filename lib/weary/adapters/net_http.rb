require 'net/http'
require 'net/https'

module Weary
  module Adapter
    class NetHttp

      class << self
        include Weary::Adapter

        def connect(request)
          connection = socket(request)
          response = connection.request prepare(request)
          Rack::Response.new response.body || "", response.code, normalize_response(response.to_hash)
        end

        def prepare(request)
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

        def socket(request)
          connection = Net::HTTP.new request.host, request.port.to_s
          connection.use_ssl = request.scheme == 'https'
          connection.verify_mode = OpenSSL::SSL::VERIFY_NONE if connection.use_ssl?
          connection
        end

        def request_class(method)
          capitalized = method.capitalize
          Net::HTTP.const_get capitalized
        end
      end

      include Weary::Adapter

      def connect(rack_request)
        self.class.connect(rack_request)
      end

    end
  end
end