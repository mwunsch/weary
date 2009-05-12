module Weary
  class Base
    
    def self.on_domain(domain)
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
      options[:via] = :get if options[:via].nil?
      
      if block_given?
        #do_something
      else
        #do something_else
      end
    end
    
  end
end