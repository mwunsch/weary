module Weary
  class Response
  
    attr_reader :raw, :method, :code, :message, :header, :content_type, :cookie, :body
    alias mime_type content_type
    
    def initialize(http_response, http_method)
      raise ArgumentError, "Must be a Net::HTTPResponse" unless http_response.is_a?(Net::HTTPResponse)
      @raw = http_response
      @method = http_method
      @code = http_response.code.to_i
      @message = http_response.message
      @header = http_response.to_hash
      @content_type = http_response.content_type
      @cookie = http_response['Set-Cookie']
      @body = http_response.body
      self.format = http_response.content_type
    end
    
    def redirected?
      @raw.is_a?(Net::HTTPRedirection)
    end
    
    def format=(type)
      @format = case type
        when 'text/xml', 'application/xml'
          :xml
        when 'application/json', 'text/json', 'application/javascript', 'text/javascript'
          :json
        when 'text/html'
          :html
        when 'application/x-yaml', 'text/yaml'
          :yaml
        when 'text/plain'
          :plain
        else
          nil
      end
    end
    
    def format
      @format
    end
    
    def follow_redirect
      if redirected?
        Request.new(@raw['location'], @method).perform
      else
        nil
      end
    end
    
    def parse
      raise StandardError, "The Response has no body. #{@method.to_s.upcase} request sent." unless @body
      case @format
        when :xml, :html
          Crack::XML.parse @body
        when :json
          Crack::JSON.parse @body
        when :yaml
          YAML::load @body
        else
          @body
      end
    end
          
  end
end