module Weary
  class Base
    
    class << self
      attr_reader :format, :domain, :url
    end
    
    
    def self.on_domain(domain)
      parse_domain = URI.extract(domain)
      raise ArgumentError, 'The domain must be a URL.' if parse_domain.empty?
      @domain = domain
    end
    
    def self.as_format(format)
      @format = format
    end
    
    def self.authenticates_with(username,password)
      @username = username
      @password = password
    end  
    
    def self.construct_url(url_string)
      @url = url_string
    end
    
    def self.declare_resource(resource, options={})
      
      # available options:
      # :via = get, post, etc.
      # :with = paramaters passed to body or query
      # :requires = members of :with that must be in the action
      #             also, :at_least => 1
      # :authenticates = boolean; uses basic_authentication
      # :forms_url = string that is created
      # :in_format = if we want to override the @@format
      
      if block_given?
        yield resource
      else
        options[:via] = :get if options[:via].nil?
      end
      
      via = options[:via].to_s.downcase
      format = @format ? @format : :json    #json is default format
      puts format
    end
    
    private
      def self.get(action,options={})
        options[:via] = :get
      end
    
      def self.post(action,options={})
        options[:via] = :post
      end
    
      def self.put(action,options={})
        options[:via] = :put
      end
    
      def self.delete(action,options={})
        options[:via] = :delete
      end
  end  
end