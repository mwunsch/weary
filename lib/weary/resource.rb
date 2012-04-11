require 'addressable/template'
require 'weary/request'

module Weary
  # A description of a resource made available by an HTTP request. That
  # description is composed primarily of a url template, the HTTP method to
  # retrieve the resource and some constraints on the parameters necessary
  # to complete the request.
  class Resource
    UnmetRequirementsError = Class.new(StandardError)

    attr_reader :method

    def initialize(method, uri, options={})
      @method = method
      @ignore_url_colons = options.delete(:ignore_url_colons) || false
      self.url uri
    end

    # An accessor method to set the url to retrieve the resource. Use either
    # brackets to delimit url variables or prefix them with a colon, like
    # Sinatra.
    #
    # Returns an Addressable::Template
    def url(uri=nil)
      unless uri.nil?
        uri.gsub!(/:(\w+)/) { "{#{$1}}" } unless @ignore_url_colons
        @uri = Addressable::Template.new(uri)
      end
      @uri
    end

    # An accessor to set optional parameters permitted by the resource.
    #
    # Returns an Array of parameters.
    def optional(*params)
      @optional = params unless params.empty?
      @optional ||= []
    end

    # An accessor to set optional parameters required in order to access the
    # resource.
    #
    # Returns an Array of parameters.
    def required(*params)
      @required = params unless params.empty?
      @required ||= []
    end

    # An accessor to set default paramers to send to the resource.
    def defaults(hash=nil)
      @defaults = hash unless hash.nil?
      @defaults ||= {}
    end

    # An accessor to set HTTP request headers.
    def headers(hash=nil)
      @headers = hash unless hash.nil?
      @headers ||= {}
    end

    # Set up a Rack::Middleware to be used by the Request (which is
    # Rack-friendly).
    def use(middleware, *args, &block)
      @middlewares ||= []
      @middlewares << [middleware, args.compact, block]
    end

    # Convenience method to set a User Agent Header
    def user_agent(agent)
      headers.update 'User-Agent' => agent
    end

    # Tell the Resource to anticipate Basic Authentication. Optionally,
    # tell the Resource what parameters to use as credentials.
    #
    # user - The parameter in which to expect the username (defaults to :username)
    # pass - The parameter in which to expect the password (defaults to :password)
    def basic_auth!(user = :username, pass = :password)
      @authenticates = :basic_auth
      @credentials = [user, pass]
    end

    # Tell the Resource to anticipate OAuth. Optionally, tell the Resource
    # what parameters to use as the consumer key and access token
    #
    # key   - The parameter in which to expect the consumer key (defaults to
    #         :consumer_key)
    # token - The parameter in which to expect the user access token (defaults
    #         to :token)
    def oauth!(key = :consumer_key, token = :token, secret = :token_secret, consumer_secret = :consumer_secret)
      @authenticates = :oauth
      @credentials = [key, token, secret, consumer_secret]
    end

    # Does the Resource anticipate some sort of authentication parameters?
    def authenticates?
      !!@authenticates
    end

    # The keys expected as parameters to the Request.
    def expected_params
      defaults.keys.map(&:to_s) | optional.map(&:to_s) | required.map(&:to_s)
    end

    # Does the Resource expect this parameter to be used to make the Request?
    def expects?(param)
      expected_params.include? param.to_s
    end

    # The parameter keys that must be fulfilled to create the Request.
    def requirements
      required.map(&:to_s) | url.keys
    end

    # Given a hash of Request parameters, do they meet the requirements?
    def meets_requirements?(params)
      requirements.reject {|k| params.keys.map(&:to_s).include? k.to_s }.empty?
    end

    # Construct the request from the given parameters.
    #
    # Yields the Request
    #
    # Returns the Request.
    # Raises a Weary::Resource::UnmetRequirementsError if the requirements
    #   are not met.
    def request(params={})
      params.delete_if {|k,v| v.nil? || v.to_s.empty? }
      params.update(defaults)
      raise UnmetRequirementsError, "Required parameters: #{requirements}" \
        unless meets_requirements? params
      credentials = pull_credentials params if authenticates?
      mapping = url.keys.map {|k| [k, params.delete(k) || params.delete(k.to_sym)] }
      request = Weary::Request.new url.expand(Hash[mapping]), @method do |r|
        r.headers headers
        if !@middlewares.nil? && !@middlewares.empty?
          @middlewares.each {|middleware| r.use *middleware }
        end
        if !expected_params.empty?
          r.params params.reject {|k,v| !expects? k }
        end
        r.send @authenticates, *credentials if authenticates?
      end
      yield request if block_given?
      request
    end
    alias build request


    private

    # Private: Separate the credentials for authentication from the other
    # request parameters.
    def pull_credentials(params)
      (@credentials || []).map do |credential|
        params.delete(credential) || params.delete(credential.to_s)
      end.compact
    end


  end
end