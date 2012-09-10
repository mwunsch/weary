require 'rack'

module Weary
  class Route
    NotFoundError = Class.new(StandardError)
    NotAllowedError = Class.new(StandardError)

    def initialize(resources, domain="")
      @resources = resources
      @domain = domain
    end

    def call(env)
      begin
        request = Rack::Request.new(env)
        resource = route(request)
        url_variables = resource.url.extract("#{@domain}#{request.path}")
        resource.request(url_variables.merge(request.params)).call(env)
      rescue NotFoundError => e
        [404, {'Content-Type' => "text/plain"}, [e.message]]
      rescue NotAllowedError => e
        [405, {'Content-Type' => "text/plain"}, [e.message]]
      rescue Weary::Resource::UnmetRequirementsError => e
        [403, {'Content-Type' => "text/plain"}, [e.message]]
      rescue Exception => e
        [500, {'Content-Type' => "text/plain"}, [e.message]]
      end
    end

    def route(request)
      subset = select_by_url("#{@domain}#{request.path}")
      raise NotFoundError, "Not Found" if subset.empty?
      subset = select_by_method(request.request_method, subset)
      raise NotAllowedError, "Method Not Allowed" if subset.empty?
      subset.first
    end

    private

    def select_by_url(url, set=@resources)
      set.select do |resource|
        mapping = resource.url.extract(url)
        if mapping.respond_to?(:empty?) && !mapping.empty?
          !mapping.values_at(*resource.url.variables).compact.empty?
        else
          !mapping.nil?
        end
      end
    end

    def select_by_method(method, set=@resources)
      set.select do |resource|
        resource.method.to_s.upcase == method
      end
    end

  end
end