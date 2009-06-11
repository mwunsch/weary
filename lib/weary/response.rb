module Weary
  class Response
  
    attr_reader :raw, :method, :code, :message, :header, :content_type, :cookie, :body, :format
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
    
    def success?
      (200..299).include?(@code)
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
    
    def follow_redirect
      if redirected?
        Request.new(@raw['location'], @method).perform
      else
        nil
      end
    end
    
    # Parse the body with Crack parsers (if XML/HTML) or Yaml parser
    def parse
      raise StandardError, "The Response has no body. #{@method.to_s.upcase} request sent." unless @body
      handle_errors
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
    
    # Search the body with a CSS/XPath selector with Nokogiri
    def search(selector)
      raise ArgumentError, "Search can only be used with an XML or HTML document." unless @format != (:xml || :html)
      doc = Nokogiri.parse(@body)
      doc.search(selector)
    end
    
    private
      def handle_errors
        case @code
          when 301,302
            raise RedirectionError, "#{@message} to #{@raw['location']}"
          when 200...400
            return
          when 400
            raise BadRequest, "Failed with #{@code}: #{@message}"
          when 401
            raise Unauthorized, "Failed with #{@code}: #{@message}"
          when 403
            raise Forbidden, "Failed with #{@code}: #{@message}"
          when 404
            raise NotFound, "Failed with #{@code}: #{@message}"
          when 405
            raise MethodNotAllowed, "Failed with #{@code}: #{@message}"
          when 409
            raise ResourceConflict, "Failed with #{@code}: #{@message}"
          when 422
            raise UnprocessableEntity, "Failed with #{@code}: #{@message}"
          when 401...500
            raise ClientError, "Failed with #{@code}: #{@message}"
          when 500...600
            raise ServerError, "Failed with #{@code}: #{@message}"
          else
            raise HTTPError, "Unknown response code: #{@code}"
        end
      end
          
  end
end