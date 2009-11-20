$:.unshift(File.dirname(__FILE__))

require 'uri'
require 'net/http'
require 'net/https'
require 'set'

require 'rubygems'
require 'crack'

gem 'nokogiri'
gem 'oauth'
autoload :Yaml, 'yaml'
autoload :Nokogiri, 'nokogiri'
autoload :OAuth, 'oauth'

require 'weary/request'
require 'weary/response'
require 'weary/resource'
require 'weary/exceptions'
require 'weary/httpverb'
require 'weary/base'

module Weary
  
  Methods = Set[:get, :post, :put, :delete, :head]
  ContentTypes = { :json  => [:json, 'json', 'application/json', 'text/json', 'application/javascript', 'text/javascript'],
                   :xml   => [:xml, 'xml', 'text/xml', 'application/xml'],
                   :html  => [:html, 'html', 'text/html'],
                   :yaml  => [:yaml, 'yaml', 'application/x-yaml', 'text/yaml'],
                   :plain => [:plain, 'plain', 'text/plain'] 
  }
  # A collection of User Agent strings that I stole from HURL (http://hurl.it)
  UserAgents = {
    "Firefox 1.5.0.12 - Mac" => "Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.8.0.12) Gecko/20070508 Firefox/1.5.0.12",
    "Firefox 1.5.0.12 - Windows" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.0.12) Gecko/20070508 Firefox/1.5.0.12",
    "Firefox 2.0.0.12 - Mac" => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-US; rv:1.8.1.12) Gecko/20080201 Firefox/2.0.0.12",
    "Firefox 2.0.0.12 - Windows" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.12) Gecko/20080201 Firefox/2.0.0.12",
    "Firefox 3.0.4 - Mac" => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.0.4) Gecko/2008102920 Firefox/3.0.4",
    "Firefox 3.0.4 - Windows" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.12) Gecko/2008102920 Firefox/3.0.4",
    "Firefox 3.5.2 - Mac" => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.1.2) Gecko/20090729 Firefox/3.5.2",
    "Firefox 3.5.2 - Windows" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.1.2) Gecko/20090729 Firefox/3.5.2",
    "Internet Explorer 5.2.3 – Mac" => "Mozilla/4.0 (compatible; MSIE 5.23; Mac_PowerPC)",
    "Internet Explorer 5.5" => "Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 5.1)",
    "Internet Explorer 6.0" => "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)",
    "Internet Explorer 7.0" => "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0)",
    "Internet Explorer 8.0" => "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.2; Trident/4.0)",
    "Lynx 2.8.4rel.1 on Linux" => "Lynx/2.8.4rel.1 libwww-FM/2.14",
    "MobileSafari 1.1.3 - iPhone" => "Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en) AppleWebKit/420.1 (KHTML, like Gecko) Version/3.0 Mobile/4A93 Safari/419.3",
    "MobileSafari 1.1.3 - iPod touch" => "Mozilla/5.0 (iPod; U; CPU like Mac OS X; en) AppleWebKit/420.1 (KHTML, like Gecko) Version/3.0 Mobile/4A93 Safari/419.3",
    "Opera 9.25 - Mac" => "Opera/9.25 (Macintosh; Intel Mac OS X; U; en)",
    "Opera 9.25 - Windows" => "Opera/9.25 (Windows NT 5.1; U; en)",
    "Safari 1.2.4 - Mac" => "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/125.5.7 (KHTML, like Gecko) Safari/125.12",
    "Safari 1.3.2 - Mac" => "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/312.8 (KHTML, like Gecko) Safari/312.6",
    "Safari 2.0.4 - Mac" => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en) AppleWebKit/419 (KHTML, like Gecko) Safari/419.3",
    "Safari 3.0.4 - Mac" => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-us) AppleWebKit/523.10.3 (KHTML, like Gecko) Version/3.0.4 Safari/523.10",
    "Safari 3.1.2 - Mac" => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_2; en-us) AppleWebKit/525.13 (KHTML, like Gecko) Version/3.1 Safari/525.13",
    "Safari 3.1.2 - Windows" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-us) AppleWebKit/525.13 (KHTML, like Gecko) Version/3.1 Safari/525.13",
    "Safari 3.2.1 - Mac" => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_5; en-us) AppleWebKit/525.27.1 (KHTML, like Gecko) Version/3.2.1 Safari/525.27.1",
    "Safari 3.2.1 - Windows" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-us) AppleWebKit/525.27.1 (KHTML, like Gecko) Version/3.2.1 Safari/525.27.1",
    "Safari 4.0.2 - Mac" => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_7; en-us) AppleWebKit/530.19.2 (KHTML, like Gecko) Version/4.0.2 Safari/530.19",
    "Safari 4.0.2 - Windows" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US) AppleWebKit/530.19.2 (KHTML, like Gecko) Version/4.0.2 Safari/530.19.1"
  }
  
  # Weary::Query quickly performs a GET request on a URL and parses the request.
  def self.Query(url)
    req = Weary::Request.new(url, :get).perform
    req.parse
  end
  
  attr_reader :resources
  
  # Sets the domain the resource is on or use it to retrieve a domain you've already set.
  # It's a getter and a setter. It's an attribute!
  #
  # If the domain is not provided and you use a URL pattern that asks for it, 
  # an exception will be raised.
  def domain(dom=nil)
    raise ArgumentError, 'No domain provided' if (dom.nil? && @domain.nil?)
    if (!dom.nil?)
      parse_domain = URI.extract(dom)
      raise ArgumentError, 'The domain must be a URL.' if parse_domain.empty?
      @domain = parse_domain[0]
    end
    return @domain
  end
  alias on_domain domain
  
  # Sets a default format to make your Requests in.
  # Defaults to JSON.
  def format(format) 
    @default_format = format
  end
  alias as_format format
  
  # Construct a URL pattern for your resources to follow.
  # You can use flags like
  # * <domain>
  # * <format>
  # * <resource>
  # To aid your construction. Defaults to "<domain><resource>.<format>"
  def url(pattern)
    @url_pattern = pattern.to_s
  end
  alias construct_url url

  def authenticates(username,password)
    @username = username
    @password = password
    return nil
  end
  alias authenticates_with authenticates
  
  def with(params)
    @always_with = params
  end
  alias always_with with
  
  # Set custom Headers for your Request
  def headers(headers)
    @headers = headers
  end
  alias set_headers headers
  
  # Set the Access Token for OAuth. This must be an OAuth::AccessToken object.
  # See http://github.com/mojodna/oauth/ to learn how to create Tokens
  # Setting this will make resources use OAuth and this token by default.
  def oauth(token)
    raise ArgumentError, "Token needs to be an OAuth::AccessToken object" unless token.is_a?(OAuth::AccessToken)
    @oauth = token
  end

  # Declare a resource. Use it with a block to setup the resource
  #
  # Methods that are understood are:
  # [<tt>via</tt>] Get, Post, etc. Defaults to a GET request
  # [<tt>with</tt>] An array of parameters that will be passed to the body or query of the request. If you pass a hash, it will define default <tt>values</tt> for params <tt>keys</tt>
  # [<tt>requires</tt>] Array of members of <tt>:with</tt> that are required by the resource.
  # [<tt>authenticates</tt>] Boolean value; does the resource require authentication?
  # [<tt>oauth</tt>] Boolean value; does the resource use OAuth?
  # [<tt>access_token</tt>] Provide the Token for OAuth. Must be an OAuth::AccessToken object.
  # [<tt>url</tt>] The url of the resource. You can use the same flags as #construct_url
  # [<tt>format</tt>] The format you would like to request. Defaults to json
  # [<tt>follows</tt>] Boolean; Does this follow redirects? Defaults to true
  # [<tt>domain</tt>] Sets the domain you would like this individual resource to be on (if you include the domain flag in <tt>url</tt>)
  # [<tt>headers</tt>] Set headers for the HTTP Request
  def declare(name,&block)
    build_resource(name, :get, block)
  end
  alias get declare
  
  def post(name,&block)
    build_resource(name, :post, block)
  end
  
  def put(name,&block)
    build_resource(name, :put, block)
  end
  
  def delete(name,&block)
    build_resource(name, :delete, block)
  end
  
  def build_resource(name,verb,block=nil)
    resource = prepare_resource(name,verb)
    block.call(resource) unless block.nil?
    form_resource(resource)
    return resource
  end
  
  def prepare_resource(name,via)
    preparation = Weary::Resource.new(name)
    preparation.via = via
    preparation.format = (@default_format || :json)
    preparation.domain = @domain
    preparation.url = (@url_pattern || "<domain><resource>.<format>")
    preparation.with = @always_with unless @always_with.nil?
    preparation.headers = @headers unless (@headers.nil? || @headers.empty?)
    if !@oauth.nil?
      preparation.oauth = true
      preparation.access_token = @oauth
    end
    return preparation
  end
  
  def form_resource(resource)
    if resource.authenticates?
      raise StandardError, "Can not authenticate unless username and password are defined" unless (@username && @password)
    end
    if resource.oauth?
      if resource.access_token.nil?
        raise StandardError, "Access Token is not provided" if @oauth.nil?
        resource.access_token = @oauth
      end
    end
    @resources ||= []
    @resources << resource.to_hash 
    craft_methods(resource)
    return resource.to_hash
  end

  private
    
    def craft_methods(resource)
      code = resouce.craft_methods
      class_eval code
      return code
    end

end