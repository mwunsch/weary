$:.unshift(File.dirname(__FILE__))

require 'uri'
require 'net/http'
require 'net/https'

require 'rubygems'
require 'crack'

gem 'nokogiri'
autoload :Yaml, 'yaml'
autoload :Nokogiri, 'nokogiri'

require 'weary/request'
require 'weary/response'
require 'weary/resource'
require 'weary/exceptions'


module Weary
  
  Methods = { :get    => [:get, :GET, /\bget\b/i],
              :post   => [:post, :POST, /\bpost\b/i],
              :put    => [:put, :PUT, /\bput\b/i],
              :delete => [:delete, :del, :DELETE, :DEL, /\bdelete\b/i],
              :head   => [:head, :HEAD, /\bhead\b/i] }
  UserAgents = { } # will be a collection of user agent strings            
  
  # Weary::Query quickly performs a GET request on a URL and parses the request.
  def self.Query(url)
    req = Weary::Request.new(url, :get).perform
    req.parse
  end
  
  attr_reader :domain, :resources
  
  # Sets the domain the resource is on. 
  #
  # If the domain is not provided and you use a URL pattern that asks for it, 
  # an exception will be raised.
  def on_domain(domain)
    parse_domain = URI.extract(domain)
    raise ArgumentError, 'The domain must be a URL.' if parse_domain.empty?
    @domain = parse_domain[0]
    return @domain
  end
  
  # Sets a default format to make your Requests in.
  # Defaults to JSON.
  def as_format(format)
    @default_format = format.to_sym
  end
  
  # Construct a URL pattern for your resources to follow.
  # You can use flags like
  # * <domain>
  # * <format>
  # * <resource>
  # To aid your construction. Defaults to "<domain><resource>.<format>"
  def construct_url(pattern)
    @url_pattern = pattern.to_s
  end

  def authenticates_with(username,password)
    @username = username
    @password = password
    return nil
  end

  # Define a resource.
  #
  # Options that are allowed are:
  # [<tt>:via</tt>] Get, Post, etc. Defaults to a GET request
  # [<tt>:with</tt>] An array of parameters that will be passed to the body or query of the request.
  # [<tt>:requires</tt>] Members of <tt>:with</tt> that are required by the resource.
  # [<tt>:authenticates</tt>] Boolean value; does the resource require authentication?
  # [<tt>:url</tt>] The url of the resource. You can use the same flags as #construct_url
  # [<tt>:format</tt>] The format you would like to request.
  # [<tt>:no_follow</tt>] Boolean; Set to true if you do not want to follow redirects.
  def declare(name,via = :get)
    @resources ||= []
    resource = prepare_resource(name,via)
    yield resource if block_given?
    construct(resource)
    return resource
  end
  
  def get(name)
    if block_given?
      resource = prepare_resource(name, :get)
      yield resource
    else
      resource = declare(name, :get)
    end
    construct(resource)
    return resource
  end
  
  def post(name)
    if block_given?
      resource = prepare_resource(name, :post)
      yield resource
    else
      resource = declare(name, :post)
    end
    construct(resource)
    return resource
  end
  
  def put(name)
    if block_given?
      resource = prepare_resource(name, :put)
      yield resource
    else
      resource = declare(name, :put)
    end
    construct(resource)
    return resource
  end
  
  def delete(name)
    if block_given?
      resource = prepare_resource(name, :delete)
      yield resource
    else
      resource = declare(name, :delete)
    end
    construct(resource)
    return resource
  end

  private
  
    def prepare_resource(name,via)
      preparation = Weary::Resource.new(name)
      preparation.via = via
      preparation.format = (@default_format || :json)
      preparation.domain = @domain
      preparation.url = (@url_pattern || "<domain><resource>.<format>")
      return preparation
    end
    
    def construct(resource)
      if resource.authenticates?
        raise StandardError, "Can not authenticate unless username and password are defined" unless (@username && @password)
      end
      @resources ||= []      
      @resources << resource.to_hash 
      craft_methods(resource)
      return resource.to_hash
    end
    
    def craft_methods(resource)
      code = %Q{
        def #{resource.name}(params={})
          options ||= {}
          url = "#{resource.url}"
      }
      unless resource.requires.nil?
        resource.requires.each do |required|
          code << %Q{raise ArgumentError, "This resource requires parameter: ':#{required}'" unless params.has_key?(:#{required}) \n}
        end
      end
      unless resource.with.empty?
        with = %Q{[#{resource.with.collect {|x| ":#{x}"}.join(',')}]}
        code << %Q{unnecessary = params.keys - #{with} \n}
        code << %Q{unnecessary.each { |x| params.delete(x) } \n}
      end
      if resource.via == (:post || :put)
        code << %Q{options[:body] = params unless params.empty? \n}
      else
        code << %Q{options[:query] = params unless params.empty? \n}
        code << %Q{url << "?" + options[:query].to_params unless options[:query].nil? \n}
      end
      if resource.authenticates?
        code << %Q{options[:basic_auth] = {:username => "#{@username}", :password => "#{@password}"} \n}
      end
      unless resource.follows_redirects?
        code << %Q{options[:no_follow] = true \n}
      end
      code << %Q{
          Weary::Request.new(url, :#{resource.via}, options).perform
        end
      }
      class_eval code
    end

end