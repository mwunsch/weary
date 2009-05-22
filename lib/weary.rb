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
require 'weary/resource'


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
    @format = format.to_sym
  end

  def authenticates_with(username,password)
    @username = username
    @password = password
  end

  def declare_resource(resource, options={})
    @resources ||= []
    location ||= @domain
    # available options:
    # :via = get, post, etc. defaults to get
    # :with = paramaters passed to body or query
    # :requires = members of :with that must be in the action
    # :authenticates = boolean; uses basic_authentication
    # :construct_url = string that is created
    # :in_format = to set format, defaults to :json
        
    r = Weary::Resource.new(resource, set_defaults(options))
    declaration = r.to_hash
    
    @resources << declaration
    
    craft_methods(r)
    return declaration
  end
  
  def get(resource,options={})
    options[:via] = :get
    declare_resource(resource,options)
  end
  
  def post(resource,options={})
    options[:via] = :post
    declare_resource(resource,options)
  end
  
  def put(resource,options={})
    options[:via] = :put
    declare_resource(resource,options)
  end
  
  def delete(resource,options={})
    options[:via] = :delete
    declare_resource(resource,options)
  end

  private
    def set_defaults(hash)
      hash[:via] ||= :get
      hash[:with] ||= []
      hash[:with] = hash[:with] | hash[:requires] unless hash[:requires].nil?
      hash[:in_format] ||= (@format || :json)
      hash[:authenticates] = false if hash[:authenticates] == "false"
      hash[:authenticates] ||= false
      return hash
    end
    
    def craft_methods(resource)
      code = %Q{
        def #{resource.name}(params={})
          options ||= {}
      }
      
      unless resource.requires.nil?
        resource.requires.each do |required|
          code << %Q{raise ArgumentError, "This resource requires parameter: :#{required}" unless params.has_key?(:#{required}) \n}
        end
      end
      
      unless resource.with.nil?
        with = "["
        resource.with.each {|x| with << ":#{x},"}
        with << "]"
        code << "unnecessary = params.keys - #{with} \n"
        code << "unnecessary.each { |x| params.delete(x) } \n"
      end
            
      if resource.via == (:post || :put)
        code << "options[:body] = params \n"
      else
        code << "options[:query] = params unless params.empty? \n"
      end
      
      if resource.authenticates?
        code << %Q{options[:basic_auth] = {:username => "#{@username}", :password => "#{@password}"} \n}
      end
      
      code << %Q{
          return options
        end
      }
      
      class_eval code
    end

end