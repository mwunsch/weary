require 'rack/response'

autoload :MultiJson, 'multi_json'
autoload :MultiXml, 'multi_xml'

module Weary
  class Response
    include Rack::Response::Helpers

    def initialize(body, status, headers)
      @response = Rack::Response.new body, status, headers
      @status = self.status
    end

    def status
      @response.status.to_i
    end

    def header
      @response.header
    end
    alias headers header

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
      @response.successful?
    end

    def redirected?
      @response.redirection?
    end

    def length
      @response.length
    end

    def call(env)
      self.finish
    end

    def parse
      raise "The response does not contain a body" if body.nil? || body.empty?
      raise "Unable to parse Content-Type: #{content_type}" unless content_type =~ /(json|xml)($|;.*)/
      case content_type.match(/(json|xml)($|;.*)/)[1]
      when 'json'
        MultiJson.decode body
      when 'xml'
        MultiXml.parse body
      end
    end
  end
end