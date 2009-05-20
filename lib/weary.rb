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
    
    craft_methods(resource, setup)
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
    
    def craft_methods(key,hash)
      if hash[key].is_a? Array
        code = %Q{ def #{key}\n }
        code << %Q{ o = self.dup \n }
        hash[key].each do |method|
          name = method.keys.to_s.to_sym
          code << %Q{ o.instance_eval %Q!}
          code << create_code_string(name,method)
          code << %Q{!\n }
        end
        code << %Q{ return o }
        code << %Q{ end\n }
        class_eval code
      elsif hash[key].is_a? Hash
        class_eval create_code_string(key,hash)
      else
        # Something went wrong here
      end
    end
    
    def create_code_string(key,hash)
      case hash[key][:via]
        when :get, :delete
          code = %Q{ def #{key}(params={})\n }
          code << %Q{ options ||= {} \n }
          code << %Q{ options[:basic_auth] = {:username => "#{@username}", :password => "#{@password}"} \n } if hash[key][:authenticates]
          code << %Q{ p "#{hash[key][:via]}".to_sym \n }
          code << %Q{ options[:query] = params \n}
          code << %Q{ pp options \n }
          code << %Q{ end\n }
          code
        when :post, :put
          code = %Q{ def #{key}=(params={})\n }
          code << %Q{ options ||= {} \n }
          code << %Q{ options[:basic_auth] = {:username => "#{@username}", :password => "#{@password}"} \n } if hash[key][:authenticates]
          code << %Q{ p "#{hash[key][:via]}".to_sym \n }
          code << %Q{ options[:body] = params \n}
          code << %Q{ pp options \n }
          code << %Q{ end\n }
          code
        else
          # Something went wrong here
      end
    end
end