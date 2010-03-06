module Weary
  class Base
    @@resources = {}
    
    attr_accessor :defaults
    
    # Assign credentials to be used when authenticating to a Resource.
    # Can be a username/password combo, or an OAuth::AccessToken
    def credentials(username,password='')
      if username.is_a?(OAuth::AccessToken)
        @credentials = username
      else
        @credentials = {:username => username, :password => password}
      end
    end
    
    # Each Weary::Base object has its own set of Resources
    def resources
      @resources ||= Marshal.load(Marshal.dump(@@resources))
    end
    
    # Make changes to a Resource given and rebuild the Request method for this object
    def modify_resource(name)
      yield resources[name] if block_given?
      rebuild_method(resources[name])
    end
    
    # Rebuild the Request Method for a given Resource. This only affects the current instance.
    def rebuild_method(resource)
      instance_eval %Q{
        def #{resource.name}(params={})
          resources[:#{resource.name}].build!(params, @defaults, @credentials)
        end
      }
    end
    
    class << self      
      # Getter for class-level resources
      def resources
        @@resources
      end
      
      # Declare a resource. Use it with a block to setup the resource
      #
      # Methods that are understood are:
      # [<tt>via</tt>] Get, Post, etc. Defaults to a GET request
      # [<tt>with</tt>] An array of parameters that will be passed to the body or query of the request. If you pass a hash, it will define default <tt>values</tt> for params <tt>keys</tt>
      # [<tt>requires</tt>] Array of members of <tt>:with</tt> that are required by the resource.
      # [<tt>authenticates</tt>] Boolean value; does the resource require authentication?
      # [<tt>url</tt>] The url of the resource. You can use the same flags as #construct_url
      # [<tt>follows</tt>] Boolean; Does this follow redirects? Defaults to true
      # [<tt>headers</tt>] Set headers for the HTTP Request
      def get(name,&block)
        build_resource(name, :get, &block)
      end
      alias declare get
      
      # Declares a Resource to be requested via POST
      def post(name,&block)
        build_resource(name, :post, &block)
      end
      
      # Declares a Resource to be requested via PUT
      def put(name,&block)
        build_resource(name, :put, &block)
      end

      # Declares a Resource to be requested via DELETE
      def delete(name,&block)
        build_resource(name, :delete, &block)
      end
      
      # Set custom default Headers for your Request
      def headers(headers)
        @headers = headers
      end
      
      # Sets the domain to be used to build default url's
      def domain(dom)
        domain = URI.extract(dom)
        raise ArgumentError, 'The domain must be a URL.' if domain.blank?
        @domain = URI.parse(domain[0]).normalize.to_s
      end
      
      # Sets a default format, used to build default Resource url's
      def format(format)
        @format = format
      end
      
      # Prepare and store the Resource
      def build_resource(name,verb,&block)
        resource = prepare_resource(name,verb)
        yield resource if block_given?
        store_resource(resource)
        build_method(resource)
        resource
      end
      
      # Prepare a Resource with set defaults
      def prepare_resource(name,via = :get)
        preparation = Weary::Resource.new(name)
        preparation.via = via
        preparation.headers = @headers unless @headers.blank?
        preparation.url = "#{@domain}#{preparation.name}." + (@format || :json).to_s if @domain
        preparation
      end
      
      # Store the resource for future use
      def store_resource(resource)
        @@resources[resource.name.to_sym] = resource
        resource
      end
      
      # Build a method to form a Request for the given Resource
      def build_method(resource)
        define_method resource.name.to_sym do |*args|
          args.blank? ? params = {} : params = args[0]
          resource.build!(params, @defaults, @credentials)
        end
      end
      
    end
  end
end