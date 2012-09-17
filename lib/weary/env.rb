module Weary
  class Env
    def initialize(request)
      @request = request
    end

    def headers
      Hash[@request.headers.map {|k,v| ["HTTP_#{k.to_s.upcase.gsub('-','_')}", v] }]
    end

    def env
      {
        'REQUEST_METHOD'  => @request.method,
        'SCRIPT_NAME'     => "",
        'PATH_INFO'       => @request.uri.path,
        'QUERY_STRING'    => @request.uri.query || "",
        'SERVER_NAME'     => @request.uri.host,
        'SERVER_PORT'     => port,
        'REQUEST_URI'     => @request.uri.request_uri,
        'HTTP_HOST'       => http_host,
        'rack.url_scheme' => @request.uri.scheme,
        'rack.input'      => @request.body,
        'weary.request'   => @request
      }.update headers
    end

    def port
      (@request.uri.port || @request.uri.inferred_port).to_s
    end

    def http_host
      uri = @request.uri
      uri.host + (uri.normalized_port ? ":#{uri.normalized_port}" : "")
    end

  end
end