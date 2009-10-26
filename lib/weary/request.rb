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
      verb = HTTPVerb.new(http_verb).normalize
      if Methods.include?(verb)
        @http_verb = verb
      else
        @http_verb = :get
      end
    end
    
    def method
      @http_verb
    end
    
    def perform
      req = http.request(request)
      response = Response.new(req, @http_verb)
      unless options[:no_follow]
        if response.redirected?
          response.follow_redirect
        else
          response
        end
      else
        response
      end
    end
    
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
          when :delete
            Net::HTTP::Delete.new(@uri.request_uri)
          when :head
            Net::HTTP::Head.new(@uri.request_uri)
        end
        prepare.body = options[:body].is_a?(Hash) ? options[:body].to_params : options[:body] if options[:body]
        prepare.basic_auth(options[:basic_auth][:username], options[:basic_auth][:password]) if options[:basic_auth]
        if options[:headers]
          options[:headers].each_pair do |key, value|
            prepare[key] = value
          end
        end
        if options[:oauth]
          options[:oauth].sign!(prepare)
        end
        prepare
      end

  end
end