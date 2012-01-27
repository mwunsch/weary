require 'addressable/template'

module Weary
  class Resource
    UnmetRequirementsError = Class.new(StandardError)

    def initialize(method, uri)
      @method = method
      @uri = Addressable::Template.new(uri)
    end

    def url(uri=nil)
      @uri = Addressable::Template.new(uri) unless uri.nil?
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

    def user_agent(agent)
      headers.update 'User-Agent' => agent
    end

    def request(params={})
      params.update(defaults)
      raise UnmetRequirementsError, "Required parameters: #{required | url.keys}" \
        unless meets_requirements? params
      mapping = url.keys.map {|k| [k, params.delete(k) || params.delete(k.to_sym)] }
      request = Weary::Request.new url.expand(Hash[mapping]), @method do |r|
        r.headers headers
      end
      yield request if block_given?
      request
    end
    alias build request

    def meets_requirements?(params)
      requirements = required.map(&:to_s) | url.keys
      requirements.reject {|k| params.keys.map(&:to_s).include? k.to_s }.empty?
    end


  end
end