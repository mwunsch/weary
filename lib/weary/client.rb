require 'weary/resource'

module Weary
  autoload :Route, 'weary/route'

  # An abstract class used to construct client libraries and the primary
  # entrance point to use the Weary framework. Client defines a DSL to describe
  # and construct a set of Resources, which in turn can generate Requests that
  # can perform HTTP actions.
  #
  # Resources are defined and stored by one of the class methods corresponding
  # to an HTTP request method. Every Resource is declared with a name that
  # acts as both a key to access the resource, and, when the class is
  # instantiated, the name of a dynamically generated instance method.
  #
  # Examples
  #
  #   class GiltSales < Weary::Client
  #     domain "https://api.gilt.com/v1"
  #
  #     required :apikey
  #
  #     optional :affid
  #
  #     get :active, "/sales/active.json"
  #
  #     get :active_in_store, "/sales/:store/active.json"
  #
  #     get :upcoming, "/sales/upcoming.json"
  #
  #     get :upcoming_in_store, "/sales/:store/upcoming.json"
  #
  #     get :detail, "/sales/:store/:sale_key/detail.json"
  #   end
  #
  #   sales = GiltSales.new
  #   sales.active_in_store :store => :women, :apikey => "my-key"
  #   # => A Weary::Request object
  #
  class Client

    # Internal: HTTP Request verbs supported by Weary. These translate to class
    # methods of Client.
    REQUEST_METHODS = [
      :copy, :delete, :get, :head, :lock, :mkcol, :move, :options,
      :patch, :post, :propfind, :proppatch, :put, :trace, :unlock
    ]

    class << self
      include Weary::Requestable

      REQUEST_METHODS.each do |request_method|
        # Generate a resource of the specified REQUEST_METHOD. This
        # method is defined for each of the REQUEST_METHODS.
        #
        # name  - A Symbol name or descriptor of a resource to dynamically
        #         generate an instance method of the same name.
        # path  - A String path to the resource. If the class's domain is set it
        #         will be prepended to this path to form the resource's uri.
        # block - An optional block to be used to further customize the resource.
        #
        # Returns a Response object describing an HTTP endpoint.
        #
        # Signature
        #
        #   <method>(name, path, &block)
        #
        # method - An HTTP request method (and member of REQUEST_METHODS).
        define_method request_method do |name, path, &block|
          resource(name, request_method.to_s.upcase, path, &block)
        end
      end

      # An accessor to set the domain where the client's resources are
      # located. This is prepended to the resources' path to form the resource
      # uri.
      #
      # host - An optional String to set the client domain.
      #
      # Returns the domain String.
      def domain(host=nil)
        @domain = host unless host.nil?
        @domain ||= ""
      end

      # An accessor to set optional parameters permitted by all
      # resources described by the client.
      #
      # params - Zero or more Symbol parameters expected by the resources.
      #
      # Returns an Array of parameters.
      def optional(*params)
        @optional = params unless params.empty?
        @optional ||= []
      end

      # An accessor to set parameters required by the all of the
      # resources of the client.
      #
      # params - Zero or more Symbol parameters required by the resources.
      #
      # Returns an Array of parameters.
      def required(*params)
        @required = params unless params.empty?
        @required ||= []
      end

      # An accessor to set default parameters to be used by the all of
      # the resources described by the client.
      #
      # hash - An optional Hash of key/value pairs describing the
      #        default parameters to be sent to the resources
      #
      # Returns a Hash of the default parameters sent to all resources.
      def defaults(hash=nil)
        @defaults = hash unless hash.nil?
        @defaults ||= {}
      end

      # Internal: Create and build a resource description of a request. The
      # resource is then stored in an internal hash, generating an instance
      # method.
      #
      # name   - A Symbol name/descriptor of the resource.
      # method - A Symbol or String of the request method used in the request.
      # path   - A String path to the resource that is appended to the domain
      #          to form the uri.
      #
      # Yields the Resource for further construction.
      #
      # Returns the generated Resource.
      def resource(name, method, path="")
        resource = Weary::Resource.new method, "#{domain}#{path}"
        resource.optional *optional
        resource.required *required
        resource.defaults defaults
        pass_values_onto_requestable resource
        yield resource if block_given?
        self[name] = resource
      end

      # A getter for the stored table of Resources.
      #
      # Returns a Hash of Resources stored by their name keys.
      def resources
        @resources ||= {}
      end

      # Store a Resource at the given key. A method is built for the
      # instances with the same name as the key that calls the request method
      # of the Resource.
      #
      # name     - A Symbol name of the Resource and the eventual name of the
      #            method that will build the request.
      # resource - The Resource object to store. When the named method is
      #            called on the client instance, this resource's request
      #            method will be called.
      #
      # Returns the stored Resource.
      def []=(name,resource)
        store name, resource
      end

      # A quick getter to retrieve a Resource from the client's
      # internal store.
      #
      # name - The Symbol name of the Resource.
      #
      # Returns the Resource stored at name.
      def [](name)
        resources[name]
      end

      # Internal: Build a Rack router for the client's resources.
      #
      # Returns a Route object of the resources at the domain.
      def route
        Weary::Route.new resources.values, domain
      end

      # A Rack middleware interface that uses the internal router to
      # determine the best Resource available.
      #
      # Returns an Array resembling a Rack response tuple.
      def call(env)
        route.call(env)
      end

      private

      # Private: Store the resource in a hash keyed by the name (as a Symbol).
      #
      # Returns the saved Resource.
      # Raises ArgumentError if you try to store anything but a Resource.
      def store(name, resource)
        raise ArgumentError, "Expected a Weary::Resource but got #{resource.inspect}" \
          unless resource.is_a? Weary::Resource
        key = name.to_sym
        build_method(key, resource)
        resources[key] = resource
      end

      # Private: Do the metaprogramming necessary for the resource names to
      # become instance methods.
      def build_method(key, resource)
        define_method(key) do |*parameters, &block|
          parameters = parameters.first || {}
          @defaults ||= {}
          request = resource.request(@defaults.merge(parameters), &block)
          self.pass_values_onto_requestable(request)
          request
        end
      end
    end

    include Weary::Requestable

    def initialize
      yield self if block_given?
    end

  end
end