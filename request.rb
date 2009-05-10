require 'pp'
require 'uri'
require 'net/http'
require 'net/https'
# require 'rubygems'

require 'core_extensions'
require 'response'



class Request

  # url is a String
  # uri is a Uri
  attr_reader :url, :method, :http_verb
  attr_accessor :uri, :options
  
  def initialize(http_verb, url, options={})
    @http_verb = http_verb
    self.uri = url
    self.options = options
  end
  
  def uri=(url)
    @uri = URI.parse(url)
  end
  
  def perform
    req = http.request(request, options.to_params)
    Response.new(req)
  end
  
  def request
    case @http_verb
      when :get, :GET, /\bget\b/i
        Net::HTTP::Get.new(@uri.path)
      when :post, :POST, /\bpost\b/i
        Net::HTTP::Post.new(@uri.path)
      when :put, :PUT, /\bput\b/i
        Net::HTTP::Put.new(@uri.path)
      when :delete, :del, :DELETE, :DEL, /\bdelete\b/i
        Net::HTTP::Delete.new(@uri.path)
      when :head, :HEAD, /\bhead\b/i
        Net::HTTP::Head.new(@uri.path)
      else
        raise ArgumentError, "Only GET, POST, PUT, DELETE, and HEAD methods are supported"
    end
  end
  
  private
    def http
      connection = Net::HTTP.new(@uri.host, @uri.port)
      connection.use_ssl = @uri.is_a?(URI::HTTPS)
      connection.verify_mode = OpenSSL::SSL::VERIFY_NONE if connection.use_ssl
      connection
    end

end

q = Request.new(:get, "http://github.com/api/v2/xml/user/show/mwunsch")
q.perform