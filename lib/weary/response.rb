require 'rack/response'

autoload :MultiJson, 'multi_json'

module Weary
  class Response
    def initialize(body, status, headers)
      @response = Rack::Response.new body, status, headers
    end

    def status
      @response.status.to_i
    end

    def header
      @response.header
    end

    def body
      buffer = ""
      @response.body.each {|chunk| buffer << chunk }
      buffer
    end

    def each(&iterator)
      @response.body.each(&iterator)
    end

    def finish
      [status, header, self]
    end

    def success?
      (200..299).include? status
    end

    def redirected?
      (300..399).include? status
    end

    def length
      @response.length
    end

    def call(env)
      self.finish
    end
  end
end