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

      def domain(host=nil)
        @domain = host unless host.nil?
        @domain ||= ""
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
        @middlewares << [middleware, *args, block]
      end

      def resource(name, method, path="")
        resource = Weary::Resource.new method, "#{domain}#{path}"
        resource.optional *optional
        resource.required *required
        resource.defaults defaults
        resource.headers headers
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
        stack = if @middlewares && !@middlewares.empty?
          stack = lambda {|r| @middlewares.each {|middleware| r.use *middleware } }
        end
        define_method(key) do |parameters={}, &block|
          request = resource.request(parameters, &block)
          stack.call(request) unless stack.nil?
          request
        end
      end
    end

  end
end