require 'addressable/template'
require 'weary/request'

module Weary
  class Resource
    UnmetRequirementsError = Class.new(StandardError)

    attr_reader :method

    def initialize(method, uri)
      @method = method
      self.url uri
    end

    def url(uri=nil)
      @uri = Addressable::Template.new(uri.gsub(/:(\w+)/) { "{#{$1}}" }) unless uri.nil?
      @uri
    end

    def optional(*params)
      @optional = params unless params.empty?
      @optional ||= []
    end

    def required(*params)
      @required = params unless params.empty?
      @required ||= []
    end

    def defaults(hash=nil)
      @defaults = hash unless hash.nil?
      @defaults ||= {}
    end

    def headers(hash=nil)
      @headers = hash unless hash.nil?
      @headers ||= {}
    end

    def use(middleware, *args, &block)
      @middlewares ||= []
      @middlewares << [middleware, args, block]
    end

    def user_agent(agent)
      headers.update 'User-Agent' => agent
    end

    def basic_auth!(user = :username, pass = :password)
      @authenticates = :basic_auth
      @credentials = [user, pass]
    end

    def oauth!(key = :consumer_key, token = :token)
      @authenticates = :oauth
      @credentials = [key, token]
    end

    def authenticates?
      !!@authenticates
    end

    def expected_params
      defaults.keys.map(&:to_s) | optional.map(&:to_s) | required.map(&:to_s)
    end

    def expects?(param)
      expected_params.include? param.to_s
    end

    def requirements
      required.map(&:to_s) | url.keys
    end

    def meets_requirements?(params)
      requirements.reject {|k| params.keys.map(&:to_s).include? k.to_s }.empty?
    end

    def request(params={})
      params.delete_if {|k,v| v.nil? || v.to_s.empty? }
      params.update(defaults)
      raise UnmetRequirementsError, "Required parameters: #{requirements}" \
        unless meets_requirements? params
      credentials = pull_credentials params if authenticates?
      mapping = url.keys.map {|k| [k, params.delete(k) || params.delete(k.to_sym)] }
      request = Weary::Request.new url.expand(Hash[mapping]), @method do |r|
        r.headers headers
        if !expected_params.empty?
          r.params params.reject {|k,v| !expects? k }
        end
        r.send @authenticates, *credentials if authenticates?
        if !@middlewares.nil? && !@middlewares.empty?
          @middlewares.each {|middleware| r.use *middleware }
        end
      end
      yield request if block_given?
      request
    end
    alias build request


    private

    def pull_credentials(params)
      (@credentials || []).map do |credential|
        params.delete(credential) || params.delete(credential.to_s)
      end.compact
    end


  end
end