require 'pp'
require 'uri'
require 'net/http'
require 'net/https'
# require 'rubygems'

require 'core_extensions'
require 'response'


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
      req = http.request(request, options.to_params)
      response = Response.new(req, @http_verb)
      if response.redirected?
        response.follow_redirect
      else
        response
      end
    end
    # I often typed in "process" when I meant "perform" so this made sense to me:
    alias process perform
    
    private
      def http
        connection = Net::HTTP.new(@uri.host, @uri.port)
        connection.use_ssl = @uri.is_a?(URI::HTTPS)
        connection.verify_mode = OpenSSL::SSL::VERIFY_NONE if connection.use_ssl
        connection
      end
    
      def request
        case @http_verb
          when :get
            Net::HTTP::Get.new(@uri.path)
          when :post
            Net::HTTP::Post.new(@uri.path)
          when :put
            Net::HTTP::Put.new(@uri.path)
          when :del
            Net::HTTP::Delete.new(@uri.path)
          when :head
            Net::HTTP::Head.new(@uri.path)
        end
      end

  end
end
# "http://github.com/api/v2/xml/user/show/mwunsch"
q = Weary::Request.new("http://github.com/api/v2/xml/user/show/mwunsch")
p q.perform