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
    end
    
    def redirected?
      @raw.is_a?(Net::HTTPRedirection)
    end
    
    def format
      @format = case @content_type
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
    
    def follow_redirect
      if redirected?
        Request.new(@raw['location'], @method).perform
      else
        nil
      end
    end
          
  end
end