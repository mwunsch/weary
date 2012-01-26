require 'future'
require 'weary/response'
require 'weary/adapters/net_http'
# An abstract class. A subclass should be something that actually opens
# a socket to make the request, e.g. Net/HTTP, Curb, etc.
module Weary
  module Adapter

    def call(env)
      perform(env).finish
    end

    def perform(env)
      req = Rack::Request.new(env)
      future do
        response = connect(req)
        yield response if block_given?
        response
      end
    end

    # request is a Rack::Request
    # This computation is performed in a Promise/Future
    # Returns a Rack::Response
    def connect(request)
      Weary::Response.new [""], 501, {"Content-Type" => "text/plain"}
    end
  end
end