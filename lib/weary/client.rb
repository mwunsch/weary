require 'weary/resource'

module Weary
  class Client

    def self.get(name, url="", &block)
      resource(name, "GET", url, &block)
    end

    def self.post(name, url="", &block)
      resource(name, "POST", url, &block)
    end

    def self.put(name, url="", &block)
      resource(name, "PUT", url, &block)
    end

    def self.resource(name, method, url="", &block)
      resource = Weary::Resource.new method, url
      yield resource if block_given?
      resource
    end

  end
end