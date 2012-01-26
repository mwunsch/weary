require 'rack/response'
require 'rack/lint'

module Weary
  class Response
    def initialize(body, status, headers)
      @response = Rack::Response.new body, status, headers
    end

    alias_method :__method__, :method

    def method_missing(*args, &block)
      @response.send(*args, &block)
    end

    def call(env)
      self.finish
    end
  end
end