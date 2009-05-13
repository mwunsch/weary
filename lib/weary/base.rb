module Weary
  class Base
    
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
      @path = resource
      
      if block_given?
        yield
      else
        options[:via] = :get if options[:via].nil?
      end
    end
    
    private
      def get(action,options={})
      end
    
      def post(action,options={})
      end
    
      def put(action,options={})
      end
    
      def delete(action,options={})
      end
    
      def head(action,options={})
      end
  end  
end