require 'typhoeus'

module Weary
  module Adapter
    class Typhoeus

      class << self
        include Weary::Adapter

        def connect(rack_request)
          response = ::Typhoeus::Request.new(rack_request.url, parameters_for(rack_request)).run
          Rack::Response.new response.body, response.code, response.headers_hash
        end

        def parameters_for(request)
          typhoeus_params = { :headers => normalize_request_headers(request.env),
                              :method  => request.request_method.downcase.to_sym,
                              :body => request.body.read }
          request.body.rewind
          typhoeus_params
        end
      end

      include Weary::Adapter

      def connect(rack_request)
        self.class.connect(rack_request)
      end

    end
  end
end