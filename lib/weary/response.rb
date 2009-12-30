module Weary
  class Response
  
    attr_reader :raw, :requester, :code, :message, :header, :content_type, :cookie, :body, :url
    
    def initialize(http_response, requester)
      @raw = http_response
      @requester = requester
      @url = requester.uri
      @code = http_response.code.to_i
      @message = http_response.message
      @header = http_response.to_hash
      @content_type = http_response.content_type
      @cookie = http_response['Set-Cookie']
      @body = http_response.body
    end
    
    # Is this an HTTP redirect?
    def redirected?
      raw.is_a?(Net::HTTPRedirection)
    end
    
    # Was this Request successful?
    def success?
      (200..299).include?(code)
    end
    
    # Returns a symbol corresponding to the Response's Content Type
    def format
      @format ||= case content_type
        when *ContentTypes[:json]
          :json
        when *ContentTypes[:xml]
          :xml
        when *ContentTypes[:html]
          :html
        when *ContentTypes[:yaml]
          :yaml
        else
          :plain
      end
    end
    
    # Follow the Redirect
    def follow_redirect
      if redirected?
        new_request = requester.dup
        new_request.uri = @raw['location']
        new_request.perform
      end  
    end
    
    # Parse the body with Crack parsers (if XML/HTML) or Yaml parser
    def parse
      raise StandardError, "The Response has no body. #{requester.via.to_s.upcase} request sent." unless body
      handle_errors
      case format
        when :xml, :html
          Crack::XML.parse body
        when :json
          Crack::JSON.parse body
        when :yaml
          YAML::load body
        else
          body
      end
    end
    
    # Same as parse[key]
    def [](key)
      parse[key]
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