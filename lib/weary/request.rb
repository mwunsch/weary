# A Request builds a rack env to hand off to an adapter,
# which is a rack application that actually makes the request
require 'json'
require 'future'
require 'addressable/uri'
require 'rack'
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
      new_env = environment.update(env)
      adapter.new.call new_env
    end

    def env
      rack_hash = {
        'REQUEST_METHOD'  => method,
        'SCRIPT_NAME'     => "",
        'PATH_INFO'       => uri.path,
        'QUERY_STRING'    => uri.query || "",
        'SERVER_NAME'     => uri.host,
        'SERVER_PORT'     => uri.port || uri.inferred_port,
        'REQUEST_URI'     => uri.request_uri,
        'rack.url_scheme' => uri.scheme,
        'rack.input'      => attachment,
        'weary.request'   => self
      }
      rack_hash.update Hash[headers.map {|k,v| ["HTTP_#{k.to_s.upcase.gsub('-','_')}", v] }]
      rack_hash
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
      if !parameters.nil?
        if ["POST", "PUT"].include? method
          @body = query_params_from_hash(parameters)
          attachment StringIO.new(@body)
        else
          uri.query_values = parameters
          @body = uri.query
        end
      end
      @body
    end

    def json(parameters)
      json = parameters.to_json
      attachment StringIO.new(json)
      json
    end

    def attachment(io=nil)
      @attachment = io unless io.nil?
      @attachment
    end

    def adapter(connection=nil)
      @connection = connection unless connection.nil?
      @connection ||= Weary::Adapter::NetHttp
    end

    def basic_auth(*credentials)
      unless credentials.empty?
        @basic_auth = [credentials.join(':')].pack('m*')
        headers.update 'Authorization' => "Basic #{@basic_auth}"
      end
      @basic_auth
    end

    # A Future comes back
    def perform
      future do
        status, headers, body = call({})
        response = Weary::Response.new body, status, headers
        yield response if block_given?
        response
      end
    end

    private

    def query_params_from_hash(hash)
      tmp_uri = Addressable::URI.new
      tmp_uri.query_values = hash
      tmp_uri.query
    end

  end
end