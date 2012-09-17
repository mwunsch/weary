require 'weary/response'

module Weary
  # An abstract interface. A subclass should be something that actually opens
  # a socket to make the request, e.g. Net/HTTP, Curb, etc.
  module Adapter
    autoload :NetHttp, 'weary/adapters/net_http'
    autoload :Excon, 'weary/adapters/excon'
    autoload :Typhoeus, 'weary/adapters/typhoeus'

    def initialize(app=nil)
      @app = app
    end

    def call(env)
      connect(Rack::Request.new(env)).finish
    end

    # request is a Rack::Request
    # This computation is performed in a Promise/Future
    # Returns a Rack::Response
    def connect(request)
      Rack::Response.new [""], 501, {"Content-Type" => "text/plain"}
    end

    # Modify the headers of an Env to be Capitalized strings with dashes (as
    # opposed to the CGI-like headers needed by Rack).
    def normalize_request_headers(env)
      req_headers = env.reject {|k,v| !k.start_with? "HTTP_" }
      normalized = req_headers.map do |k, v|
        new_key = k.sub("HTTP_",'').split('_').map(&:capitalize).join('-')
        [new_key, v] unless UNWANTED_REQUEST_HEADERS.include? new_key
      end
      Hash[normalized]
    end

    # According to the Rack Spec:
    # > The header must not contain a Status key...
    def normalize_response(headers)
      headers.reject {|k,v| k.downcase == 'status' }
    end

    protected

    UNWANTED_REQUEST_HEADERS = []
  end
end