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
      if (options[:body])
        self.with = options[:body]
      end
      self.headers = options[:headers] if options[:headers]
      self.follows = true
      if options.has_key?(:no_follow)
        self.follows = options[:no_follow] ? false : true
      end
    end
  
    def uri=(url)
      @uri = URI.parse(url)
      if (with && !request_preparation.request_body_permitted?)
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
    
    def with=(params)
      @with = (params.respond_to?(:to_params) ? params.to_params : params)
      if (!request_preparation.request_body_permitted?)
        uri.query = @with
      end
    end
    
    def credentials=(auth)
      if auth.is_a?(OAuth::AccessToken)
        @credentials = auth
      else
        @credentials = {:username => auth[:username], :password => auth[:password]}
      end
    end
    
    def follows=(bool)
      @follows = (bool ? true : false)
    end
    
    def follows?
      @follows
    end
    
    def on_complete(&block)
      @on_complete = block if block_given?
      @on_complete
    end
    
    def before_send(&block)
      @before_send = block if block_given?
      @before_send
    end
    
    def perform(&block)
      @on_complete = block if block_given?
      before_send.call(self) if before_send
      req = http.request(request)
      response = Response.new(req, self)
      if response.redirected?
        return response.follow_redirect if follows?
      end
      on_complete.call(response) if on_complete
      response
    end    
    
    def http
      connection = Net::HTTP.new(uri.host, uri.port)
      connection.use_ssl = uri.is_a?(URI::HTTPS)
      connection.verify_mode = OpenSSL::SSL::VERIFY_NONE if connection.use_ssl
      connection
    end
    
    def request
      req = request_preparation
      
      req.body = with if (with && req.request_body_permitted?)
      if (credentials)
        if (credentials.is_a?(OAuth::AccessToken))
          credentials.sign!(req)
        else
          req.basic_auth(credentials[:username], credentials[:password])
        end
      end
      
      if headers
        headers.each_pair do |key, value|
          req[key] = value
        end
      end
      
      req
    end
    
    def request_preparation
      HTTPVerb.new(via).request_class.new(uri.request_uri)
    end

  end
end