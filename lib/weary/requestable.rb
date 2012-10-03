module Weary
  module Requestable

    # An accessor to set a Weary::Adapter to use to forward the connection.
    # When a request is made, it will be passed along to this adapter to
    # get the eventual Response. Defaults to Weary::Adapter::NetHttp.
    #
    # connection - An optional Weary::Adapter.
    #
    # Returns the Weary::Adapter.
    def adapter(connection=nil)
      @connection = connection unless connection.nil?
      @connection ||= Weary::Adapter::NetHttp
    end

    # An accessor to set HTTP request headers.
    #
    # hash - An optional Hash of key/value pairs that are sent as HTTP
    #        request headers when a resource's request is performed.
    #
    # Returns a Hash of the headers.
    def headers(hash=nil)
      @headers = hash unless hash.nil?
      @headers ||= {}
    end

    # Send a Rack middleware to be used by the Request.
    #
    # middleware - An object that implements the rack middleware interface.
    # args       - Zero or more optional arguments to send to the middleware.
    # block      - An optional block to send to the middleware.
    #
    # Returns an Array of middlewares.
    def use(middleware, *args, &block)
      @middlewares ||= []
      @middlewares << [middleware, args.compact, block]
    end

    # Convenience method to set a User Agent Header
    #
    # agent - A user agent String. See Weary::USER_AGENTS for some help
    #
    # Returns the updated headers Hash.
    def user_agent(agent)
      headers.update 'User-Agent' => agent
    end

    # Should the Request use one or more Rack::Middleware?
    def has_middleware?
      !@middlewares.nil? && !@middlewares.empty?
    end

    # Pass Requestable values on to another Requestable object
    # (including Middleware).
    #
    # requestable - Another Requestable object.
    #
    # Returns the Requestable object.
    def pass_values_onto_requestable(requestable)
      requestable.headers self.headers unless @headers.nil?
      requestable.adapter self.adapter unless @connection.nil?
      if has_middleware?
        @middlewares.each {|middleware| requestable.use *middleware }
      end
      requestable
    end

  end
end