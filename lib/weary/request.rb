module Weary
  class Request
    
    attr_reader :uri
    attr_accessor :options
  
    def initialize(url, http_verb= :get, options={})
      self.method = http_verb
      self.uri = url
      self.options = options
    end
  
    def uri=(url)
      @uri = URI.parse(url)
    end
    
    def method=(http_verb)
      @http_verb = case http_verb
        when :get, :GET, /\bget\b/i
          :get
        when :post, :POST, /\bpost\b/i
          :post
        when :put, :PUT, /\bput\b/i
          :put
        when :delete, :del, :DELETE, :DEL, /\bdelete\b/i
          :del
        when :head, :HEAD, /\bhead\b/i
          :head
        else
          raise ArgumentError, "Only GET, POST, PUT, DELETE, and HEAD methods are supported"
      end
    end
    
    def method
      @http_verb
    end
  
    def perform
      req = http.request(request)
      response = Response.new(req, @http_verb)
      if response.redirected?
        response.follow_redirect
      else
        response
      end
    end
    alias make perform
    
    private
      def http
        connection = Net::HTTP.new(@uri.host, @uri.port)
        connection.use_ssl = @uri.is_a?(URI::HTTPS)
        connection.verify_mode = OpenSSL::SSL::VERIFY_NONE if connection.use_ssl
        connection
      end
    
      def request
        prepare = case @http_verb
          when :get
            Net::HTTP::Get.new(@uri.request_uri)
          when :post
            Net::HTTP::Post.new(@uri.request_uri)
          when :put
            Net::HTTP::Put.new(@uri.request_uri)
          when :del
            Net::HTTP::Delete.new(@uri.request_uri)
          when :head
            Net::HTTP::Head.new(@uri.request_uri)
        end
        prepare.body = options[:body].is_a?(Hash) ? options[:body].to_params : options[:body] if options[:body]
        prepare.basic_auth(options[:basic_auth][:username], options[:basic_auth][:password]) if options[:basic_auth]
        prepare
      end

  end
end