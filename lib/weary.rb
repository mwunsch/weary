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


module Weary
  
  # Weary::Query quickly performs a :get request on a URL and parses the request
  def self.Query(url)
    req = Weary::Request.new(url, :get).perform
    req.parse
  end
  
  attr_reader :domain, :resources
  
  def on_domain(domain)
    parse_domain = URI.extract(domain)
    raise ArgumentError, 'The domain must be a URL.' if parse_domain.empty?
    @domain = parse_domain[0]
  end

  def as_format(format)
    @format = format
  end

  def authenticates_with(username,password)
    @username = username
    @password = password
  end

  def declare_resource(resource, options={})
    # available options:
    # :via = get, post, etc. defaults to get
    # :with = paramaters passed to body or query
    # :requires = members of :with that must be in the action
    #             also, :at_least => 1
    # :authenticates = boolean; uses basic_authentication
    # :construct_url = string that is created
    # :in_format = to set format, defaults to :json
    
    @methods = []
    setup = {}

    if block_given?
      setup[resource] = yield
    else
      set_options(options)
      setup[resource] = options
    end
    
    @resources ||= []  
    @resources << setup
    
    define_methods(setup[resource])
  end

  private
    def get(method,options={})
      options[:via] = :get
      set_options(options)
      set_action(method,options)
    end

    def post(method,options={})
      options[:via] = :post
      set_options(options)
      set_action(method,options)
    end

    def put(method,options={})
      options[:via] = :put
      set_options(options)
      set_action(method,options)
    end

    def delete(method,options={})
      options[:via] = :delete
      set_options(options)
      set_action(method,options)
    end
    
    def set_options(hash)
      hash[:with] ||= []
      hash[:via] ||= :get
      hash[:in_format] ||= (@format || :json)
      hash[:authenticates] ||= false
      hash[:with].concat(hash[:requires]) unless hash[:requires].nil?
      
      return nil
    end
    
    def set_action(method,options)
      action = {}
      action[method.to_sym] = options
      @methods << action
    end
    
    def define_methods(key)
      code = ""
      if key.is_a? Array
        "Array"
      elsif Hash
        "Hash"
      else
        "Something Else"
      end
    end
end