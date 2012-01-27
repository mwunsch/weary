# A Request builds a rack env to hand off to an adapter,
# which is a rack application that actually makes the request
require 'addressable/uri'
require 'rack/request'
require 'weary/adapter'

module Weary
  class Request
    attr_reader :uri

    def initialize(url, method='GET')
      self.uri = url
      self.method = method
      yield self if block_given?
    end

    def uri=(url)
      uri = Addressable::URI.parse(url).normalize!
      @uri = uri
    end

    def call(environment)
      perform.finish
    end

    def env
      {
        'REQUEST_METHOD'  => method,
        'SCRIPT_NAME'     => "",
        'PATH_INFO'       => uri.path,
        'QUERY_STRING'    => uri.query || "",
        'SERVER_NAME'     => uri.host,
        'SERVER_PORT'     => uri.port || uri.inferred_port,
        'REQUEST_URI'     => uri.request_uri,
        'rack.url_scheme' => uri.scheme,
        'weary.request'   => self
      }.update Hash[headers.map {|k,v| ["HTTP_#{k.to_s.upcase.gsub('-','_')}", v] }]
    end

    alias_method :__method__, :method

    def method
      @method
    end

    def method=(verb)
      @method = verb.to_s.upcase
    end

    def headers(hash=nil)
      @headers = hash unless hash.nil?
      @headers ||= {}
    end

    def user_agent(agent)
      headers.update 'User-Agent' => agent
    end

    def body(parameters=nil)
    end

    def adapter(connection=nil)
      @connection = connection unless connection.nil?
      @connection ||= Weary::Adapter::NetHttp
    end

    # A Future comes back
    def perform(&block)
      adapter.new.perform env, &block
    end

  end
end