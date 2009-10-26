$:.unshift(File.dirname(__FILE__))

require 'uri'
require 'net/http'
require 'net/https'

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
          with = %Q{[#{resource.with.collect {|x| x.is_a?(Symbol) ? ":#{x}" : "'#{x}'" }.join(',')}]}
        else
          with = %Q{[#{resource.with.keys.collect {|x| x.is_a?(Symbol) ? ":#{x}" : "'#{x}'"}.join(',')}]}
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
      if resource.oauth?
        consumer_options = ""
        resource.access_token.consumer.options.each_pair {|k,v| 
          if k.is_a?(Symbol)
            k_string = ":#{k}"
          else
            k_string = "'#{k}'"
          end
          if v.is_a?(Symbol)
            v_string = ":#{v}"
          else
            v_string = "'#{v}'"
          end
          consumer_options << "#{k_string} => #{v_string},"
        }
        code << %Q{ oauth_consumer = OAuth::Consumer.new("#{resource.access_token.consumer.key}","#{resource.access_token.consumer.secret}",#{consumer_options.chop}) \n}
        code << %Q{ options[:oauth] = OAuth::AccessToken.new(oauth_consumer, "#{resource.access_token.token}", "#{resource.access_token.secret}") \n}
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