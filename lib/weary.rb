require 'pp'
require 'uri'
require 'net/http'
require 'net/https'
require 'rubygems'

gem 'crack'
gem 'nokogiri'

autoload :Yaml, 'yaml'
autoload :Crack, 'crack'
autoload :Nokogiri, 'nokogiri'

require 'weary/core_extensions'
require 'weary/request'
require 'weary/response'
require 'weary/base'

module Weary
  
  attr_reader :format, :domain, :url, :resources
  
  def on_domain(domain)
    parse_domain = URI.extract(domain)
    raise ArgumentError, 'The domain must be a URL.' if parse_domain.empty?
    @domain = domain
  end

  def as_format(format)
    @format = format
  end

  def authenticates_with(username,password)
    @username = username
    @password = password
  end  

  def construct_url(pattern)
    @url = @domain + pattern
  end

  def declare_resource(resource, options={})
    @resources ||= []
    @method_array = []
    setup = {}
    
    # available options:
    # :via = get, post, etc.
    # :with = paramaters passed to body or query
    # :requires = members of :with that must be in the action
    #             also, :at_least => 1
    # :authenticates = boolean; uses basic_authentication
    # :construct_url = string that is created
    # :in_format = if we want to override the @@format

    if block_given?
      setup[resource] = yield
    else
      options[:via] = :get if options[:via].nil?
      setup[resource] = options
    end

    via = options[:via].to_s.downcase
    format = @format ? @format : :json
    format = options[:in_format] unless options[:in_format].nil?
    
    @resources << setup
  end

  private
    def get(method,options={})
      action = {}
      options[:via] = :get
      action[method.to_sym] = options
      @method_array << action
    end

    def post(method,options={})
      action = {}
      options[:via] = :post
      action[method.to_sym] = options
      @method_array << action
    end

    def put(method,options={})
      options[:method] = method.to_s
      options[:via] = :put
      options
    end

    def delete(method,options={})
      options[:method] = method.to_s
      options[:via] = :delete
      options
    end
  
  # Weary::Query quickly performs a :get request on a URL and parses the request
  def self.Query(url)
    req = Weary::Request.new(url, :get).perform
    req.parse
  end
  
end

# req = Weary::Request.new "http://github.com/api/v2/json/user/show/mwunsch"
# doc = Weary::Query "http://github.com/api/v2/xml/user/show/mwunsch"
# 
# pp doc