require 'pp'
require 'uri'
require 'net/http'
require 'net/https'
# require 'rubygems'

require 'core_extensions'



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
    http.request(request, options.to_params)
  end
  
  def request
    case @http_verb
      when :get, :GET, /\bget\b/i
        Net::HTTP::Get.new(@uri.path)
      when :post, :POST, /\bpost\b/i
        Net::HTTP::Post.new(@uri.path, options.to_params)
      when :head, :HEAD, /\bhead\b/i
        Net::HTTP::Head.new(@uri.path, options.to_params)
      else
        puts "HALP"
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

q = Request.new(:get, "https://github.com/api/v2/xml/user/show/mwunsch")
puts q.perform