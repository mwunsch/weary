require 'weary/response'

module Weary
  # A handy abstract proxy class that is used to proxy a domain model
  # in an asynchronous fashion. Useful if you're not interested in a
  # Weary::Response object, but you want to pass that into a domain object
  # when the response is available.
  class Deferred < defined?(::BasicObject) ? ::BasicObject : ::Object

    instance_methods.each {|m| undef_method(m) if m.to_s !~ /(?:^__|^nil\?$|^send$|^object_id$)/ } \
      unless defined? ::BasicObject

    attr_reader :callable

    def initialize(future, model, callable=nil)
      @future = future
      @model = model
      @callable = callable || ::Proc.new{|klass, response| klass.new(response) }
      @target = nil
    end

    def complete?
      !!@target
    end

    def method_missing(method, *args, &block)
      if @model.method_defined? method
        @target ||= @callable.call @model, @future
        @target.send(method, *args, &block)
      else
        super
      end
    end
  end
end