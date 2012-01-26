require 'addressable/template'

module Weary
  class Resource

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

    def request(params={})
      params.update(defaults)
      Weary::Request.new(url.expand({}), @method)
    end
    alias build request

  end
end