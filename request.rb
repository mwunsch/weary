require 'pp'
require 'uri'
require 'net/http'
# require 'net/https'
# require 'rubygems'
# require 'crack'
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
    http.request(request)
  end
  
  def request
    case @http_verb
      when :get, :GET, /\bget\b/i
        Net::HTTP::Get.new(@uri.path)
      when :post, :POST, /\bpost\b/i
        Net::HTTP::Post.new(@uri.path)
      when :head, :HEAD, /\bhead\b/i
        Net::HTTP::Head.new(@uri.path)
      else
        puts "HALP"
    end
  end
  
  private
    def http
      connection = Net::HTTP.new(@uri.host, @uri.port)
      connection
    end

end

q = Request.new(:get, "http://google.com")
puts q.perform