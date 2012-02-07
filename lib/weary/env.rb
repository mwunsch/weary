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
        'SERVER_PORT'     => (@request.uri.port || @request.uri.inferred_port).to_s,
        'REQUEST_URI'     => @request.uri.request_uri,
        'rack.url_scheme' => @request.uri.scheme,
        'rack.input'      => @request.body,
        'weary.request'   => @request
      }.update headers
    end
  end
end