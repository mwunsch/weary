module Weary
  class Resource
    attr_reader :name, :via, :with, :requires, :url
    attr_accessor :headers
    
    def initialize(name)
      self.name = name.to_sym
      self.via = :get
      self.authenticates = false
      self.follows = true
    end
    
    # The name of the Resource. Will be a lowercase string, whitespace replaced with underscores.
    def name=(resource_name)
      @name = resource_name.to_s.downcase.strip.gsub(/\s/,'_')
    end
    
    # The HTTP Method used to fetch the Resource
    def via=(http_verb)
      verb = HTTPVerb.new(http_verb).normalize
      @via = Methods.include?(verb) ? verb : :get
    end
    
    # Optional params. Should be an array. Merges with requires if that is set.
    def with=(params)
      @with = [params].flatten.collect {|x| x.to_sym}
      @with = (requires | @with) if requires
    end
    
    # Required params. Should be an array. Merges with `with` or sets `with`.
    def requires=(params)
      @requires = [params].flatten.collect {|x| x.to_sym}
      with ? @with = (with | @requires) : (@with = @requires)
    end
    
    # Sets whether the Resource requires authentication. Always sets to a boolean value.
    def authenticates=(bool)
      @authenticates = bool ? true : false
    end
    
    # Does the Resource require authentication?
    def authenticates?
      @authenticates
    end
    
    # Sets whether the Resource should follow redirection. Always sets to a boolean value.
    def follows=(bool)
      @follows = bool ? true : false
    end
    
    # Should the resource follow redirection?
    def follows?
      @follows
    end
    
    # Set the Resource's URL as a URI
    def url=(uri)
      @url = URI.parse(uri)
    end
    
    # A hash representation of the Resource
    def to_hash
      {@name.to_sym => { :via => via,
                         :with => with,
                         :requires => requires,
                         :follows => follows?,
                         :authenticates => authenticates?,
                         :url => url,
                         :headers => headers}}
    end
    
    # Take parameters, default params, and credentials and build a Request object for this Resource
    def build!(params={}, defaults=nil, credentials=nil)
      uri = @url
      parameters = setup_parameters(params, defaults)
      request_opts = setup_options(parameters, credentials)
      uri.query = request_opts[:query].to_params if request_opts[:query]
      Request.new(uri.normalize.to_s, @via, request_opts)
    end
    
    # Setup the parameters to make the Request with
    def setup_parameters(params={}, defaults=nil)
      params = defaults ? defaults.merge(params) : params
      find_missing_requirements(params)
      remove_unnecessary_params(params)
    end
    
    # Search the given parameters to see if they are missing any required params
    def find_missing_requirements(params)
      if (@requires && !@requires.empty?)
        missing_requirements = @requires - params.keys
        raise ArgumentError, "This resource is missing required parameters: '#{missing_requirements.inspect}'" unless missing_requirements.empty?
      end
    end
    
    # Remove params that have not been specified with #with
    def remove_unnecessary_params(params)
      params.delete_if {|k,v| !@with.include?(k) } if (@with && !@with.empty?)
    end
    
    # Setup the options to be passed into the Request
    def setup_options(params={}, credentials=nil)
      options = {}
      prepare_request_body(params, options)
      setup_authentication(options, credentials)
      options[:no_follow] = true if !follows?
      options[:headers] = @headers if !@headers.blank?
      options
    end
    
    # Prepare the Request query or body depending on the HTTP method
    def prepare_request_body(params, options={})
      if (@via == :post || @via == :put)
          options[:body] = params unless params.blank?
      else
          options[:query] = params unless params.blank?
      end
      options
    end
    
    # Prepare authentication credentials for the Request
    def setup_authentication(options, credentials=nil)
      if authenticates?
        raise ArgumentError, "This resource requires authentication and no credentials were given." if credentials.blank?
        if credentials.is_a?(OAuth::AccessToken)
          options[:oauth] = credentials
        else
          options[:basic_auth] = credentials
        end
      end
      options
    end
    
  end
end