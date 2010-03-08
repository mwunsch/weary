module Weary
  class Request
    
    attr_reader :uri, :with, :credentials
    attr_accessor :headers
  
    def initialize(url, http_verb= :get, options={})
      self.uri = url
      self.via = http_verb
      self.credentials = {:username => options[:basic_auth][:username], 
                          :password => options[:basic_auth][:password]} if options[:basic_auth]
      self.credentials = options[:oauth] if options[:oauth]
      self.with = options[:body] if options[:body]
      self.headers = options[:headers] if options[:headers]
      self.follows = options[:no_follow] ? false : true
    end
    
    # Create a URI object for the given URL
    def uri=(url)
      @uri = URI.parse(url)
      if (with && !connection.request_body_permitted?)
        @uri.query = with
      end
    end
    
    def via=(http_verb)
      verb = HTTPVerb.new(http_verb).normalize
      @http_verb = if Methods.include?(verb)
        verb
      else
        :get
      end
    end
    
    def via
      @http_verb
    end
    
    # Set parameters to send with the Request.
    # If this Request does not accept a body (a GET request for instance),
    # set the query string for the url.
    def with=(params)
      @with = (params.respond_to?(:to_params) ? params.to_params : params)
      if (!connection.request_body_permitted?)
        uri.query = @with
      end
    end
    
    # Credentials to send to Authorize the Request
    # For basic auth, use a hash with keys :username and :password
    # For OAuth, use an Access Token
    def credentials=(auth)
      if auth.is_a?(OAuth::AccessToken)
        @credentials = auth
      else
        @credentials = {:username => auth[:username], :password => auth[:password]}
      end
    end
    
    # Should the Request follow redirects?
    def follows=(bool)
      @follows = (bool ? true : false)
    end

    def follows?
      @follows
    end
    
    # A callback that is triggered after the Response is received.
    def on_complete(&block)
      @on_complete = block if block_given?
      @on_complete
    end
    
    # A callback that is sent before the Request is fired.
    def before_send(&block)
      @before_send = block if block_given?
      @before_send
    end
    
    # Perform the Request, returns the Response. Pass a block in to use
    # as the on_complete callback.
    def perform(&block)
      @on_complete = block if block_given?
      response = perform!
      response.value
    end
    
    # Spins off a new thread to perform the Request.
    def perform!(&block)
      @on_complete = block if block_given?
      Thread.new {
        before_send.call(self) if before_send
        req = http.request(request)
        response = Response.new(req, self)
        if response.redirected? && follows?
          response.follow_redirect
        else
          on_complete.call(response) if on_complete
          response
        end
      }
    end
    
    # Build the HTTP connection.
    def http
      socket = Net::HTTP.new(uri.host, uri.port)
      socket.use_ssl = uri.is_a?(URI::HTTPS)
      socket.verify_mode = OpenSSL::SSL::VERIFY_NONE if socket.use_ssl?
      socket
    end
    
    # Build the HTTP Request.
    def request
      req = connection
      
      req.body = with if (with && req.request_body_permitted?)
      if (credentials)
        if (credentials.is_a?(OAuth::AccessToken))
          credentials.sign!(req)
        else
          req.basic_auth(credentials[:username], credentials[:password])
        end
      end
      
      headers.each_pair {|key,value| req[key] = value } if headers
      
      req
    end
    
    # Prepare the HTTP Request.
    # The Request has a lifecycle:
    # Prepare with `request_preparation`
    # Build with `request`
    # Fire with `perform`
    def connection
      HTTPVerb.new(via).request_class.new(uri.request_uri)
    end

  end
end