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
      setup[resource] = set_options(options)
    end
    
    @resources ||= []
    @resources << setup
    
    craft_methods(resource, setup)
    return setup
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
      hash[:via] ||= :get
      hash[:with] ||= []
      hash[:with] = hash[:with] | hash[:requires] unless hash[:requires].nil?
      hash[:in_format] ||= (@format || :json)
      hash[:authenticates] ||= false
      return hash
    end
    
    def set_action(method,options)
      action = {}
      action[method.to_sym] = options
      @methods << action
    end
    
    def craft_methods(key,hash)
      if hash[key].is_a? Array
        code = %Q{ def #{key}\n }
        code << %Q{ obj = self.dup \n }
        hash[key].each do |method|
          name = method.keys.to_s.to_sym
          code << %Q{ obj.instance_eval %Q!}
          code << create_code_string(name,method,key+"/")
          code << %Q{!\n }
        end
        code << %Q{ return obj }
        code << %Q{ end\n }
        class_eval code
      elsif hash[key].is_a? Hash
        class_eval create_code_string(key,hash)
      else
        # Something went wrong here
      end
    end
    
    def create_code_string(key,hash,resource="")
      format = hash[key][:in_format]
      code = %Q{ def #{key}(params={})\n }
      code << "options ||= {} \n"
      
      case hash[key][:via]
        when :get, :delete
          code << %Q{ options[:query] = params unless params.empty? \n }
        when :post, :put
          code << %Q{ options[:body] = params \n }
        else
          # Something went wrong here
      end
      
      unless hash[key][:with].empty?
        with_a = "["
        hash[key][:with].each { |x| with_a << ":#{x}," }
        with_a << "]"
        code << %Q{ unnecessary = params.keys - #{with_a} \n }
        code << %Q{ unnecessary.each { |x| params.delete(x) } \n}
      end      
      if hash[key][:requires] && !hash[key][:requires].empty?
        hash[key][:requires].each do |required|
          code << %Q{ raise ArgumentError, ":#{required} is a required parameter." unless params.has_key?(:#{required}) \n }
        end
      end
      
      code << %Q{ location = "#{domain}#{resource}#{key}.#{format}" \n }
      code << %Q{ options[:basic_auth] = {:username => "#{@username}", :password => "#{@password}"} \n } if hash[key][:authenticates]
      code << %Q{ return Weary::Request.new(location, :#{hash[key][:via]}, options) \n }
      code << %Q{ end\n }
      
      return code
    end
end