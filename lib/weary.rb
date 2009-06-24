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
  ContentTypes = { :json  => [:json, 'json', 'application/json', 'text/json', 'application/javascript', 'text/javascript'],
                   :xml   => [:xml, 'xml', 'text/xml', 'application/xml'],
                   :html  => [:html, 'html', 'text/html'],
                   :yaml  => [:yaml, 'yaml', 'application/x-yaml', 'text/yaml'],
                   :plain => [:plain, 'plain', 'text/plain'] }
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
    @default_format = format
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
  
  def always_with(params)
    @always_with = params
  end
  
  # Set custom Headers for your Request
  def set_headers(headers)
    @headers = headers
  end

  # Declare a resource. Use it with a block to setup the resource
  #
  # Methods that are understood are:
  # [<tt>via</tt>] Get, Post, etc. Defaults to a GET request
  # [<tt>with</tt>] An array of parameters that will be passed to the body or query of the request. If you pass a hash, it will define default <tt>values</tt> for params <tt>keys</tt>
  # [<tt>requires</tt>] Array of members of <tt>:with</tt> that are required by the resource.
  # [<tt>authenticates</tt>] Boolean value; does the resource require authentication?
  # [<tt>url</tt>] The url of the resource. You can use the same flags as #construct_url
  # [<tt>format</tt>] The format you would like to request. Defaults to json
  # [<tt>follows</tt>] Boolean; Does this follow redirects? Defaults to true
  # [<tt>domain</tt>] Sets the domain you would like this individual resource to be on (if you include the domain flag in <tt>url</tt>)
  def declare(name)
    resource = prepare_resource(name,:get)
    yield resource if block_given?
    form_resource(resource)
    return resource
  end
  alias get declare
  
  def post(name)
    resource = prepare_resource(name,:post)
    yield resource if block_given?
    form_resource(resource)
    return resource
  end
  
  def put(name)
    resource = prepare_resource(name,:put)
    yield resource if block_given?
    form_resource(resource)
    return resource
  end
  
  def delete(name)
    resource = prepare_resource(name,:delete)
    yield resource if block_given?
    form_resource(resource)
    return resource
  end

  private
  
    def prepare_resource(name,via)
      preparation = Weary::Resource.new(name)
      preparation.via = via
      preparation.format = (@default_format || :json)
      preparation.domain = @domain
      preparation.url = (@url_pattern || "<domain><resource>.<format>")
      preparation.with = @always_with unless @always_with.nil?
      preparation.headers = @headers unless (@headers.nil? || @headers.empty?)
      return preparation
    end
    
    def form_resource(resource)
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
      if resource.with.is_a?(Hash)
        hash_string = ""
        resource.with.each_pair {|k,v| 
          if k.is_a?(Symbol)
            k_string = ":#{k}"
          else
            k_string = "'#{k}'"
          end
          hash_string << "#{k_string} => '#{v}',"
        }
        code << %Q{
          params = {#{hash_string.chop}}.delete_if {|key,value| value.empty? }.merge(params)
        }
      end
      unless resource.requires.nil?
        if resource.requires.is_a?(Array)
          resource.requires.each do |required|
            code << %Q{  raise ArgumentError, "This resource requires parameter: ':#{required}'" unless params.has_key?(:#{required}) \n}
          end
        else
          resource.requires.each_key do |required|
            code << %Q{  raise ArgumentError, "This resource requires parameter: ':#{required}'" unless params.has_key?(:#{required}) \n}
          end
        end
      end
      unless resource.with.empty?
        if resource.with.is_a?(Array)
          with = %Q{[#{resource.with.collect {|x| ":#{x}"}.join(',')}]}
        else
          with = %Q{[#{resource.with.keys.collect {|x| ":#{x}"}.join(',')}]}
        end
        code << %Q{ 
          unnecessary = params.keys - #{with} 
          unnecessary.each { |x| params.delete(x) } 
        }
      end
      if resource.via == (:post || :put)
        code << %Q{options[:body] = params unless params.empty? \n}
      else
        code << %Q{
          options[:query] = params unless params.empty?
          url << "?" + options[:query].to_params unless options[:query].nil?
        }
      end
      unless (resource.headers.nil? || resource.headers.empty?)
        header_hash = ""
        resource.headers.each_pair {|k,v|
          header_hash << "'#{k}' => '#{v}',"
        }
        code << %Q{ options[:headers] = {#{header_hash.chop}} \n}
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
      return code
    end

end