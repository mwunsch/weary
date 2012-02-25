require 'weary/resource'

module Weary
  class Client

    REQUEST_METHODS = [
      :copy, :delete, :get, :head, :lock, :mkcol, :move, :options,
      :patch, :post, :propfind, :proppatch, :put, :trace, :unlock
    ]

    class << self
      REQUEST_METHODS.each do |request_method|
        define_method request_method do |name, path="", &block|
          resource(name, request_method.to_s.upcase, path, &block)
        end
      end

      def resource(name, method, path="")
        resource = Weary::Resource.new method, path
        yield resource if block_given?
        self[name] = resource
      end

      def resources
        @resources ||= {}
      end

      def []=(name,resource)
        store name, resource
      end

      def [](name)
        resources[name]
      end

      private

      def store(name, resource)
        raise ArgumentError, "Expected a Weary::Resource but got #{resource.inspect}" \
          unless resource.is_a? Weary::Resource
        key = name.to_sym
        build_method(key, resource)
        resources[key] = resource
      end

      def build_method(key, resource)
        define_method(key) {|parameters={}, &block| resource.request(parameters, &block) }
      end
    end

  end
end