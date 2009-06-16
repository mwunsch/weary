require 'rubygems'
gem 'rspec'
require 'spec'
require File.join(File.dirname(__FILE__), '..', 'lib', 'weary')

def get_fixture(filename)
  open(File.join(File.dirname(__FILE__), 'fixtures', "#{filename.to_s}")).read
end

def mock_response(request_method = :get, code=200, header={}, body=nil)
  response_class = Net::HTTPResponse::CODE_TO_OBJ[code.to_s]
  message = case code
    when 200
      "OK"
    when 301
      "Moved Permanently"
    when 302
      "Moved Temporarily"
    when 400
      "Bad Request"
    when 401
      "Unauthorized"
    when 403
      "Forbidden"
    when 404
      "Not Found"
    when 405
      "Method Not Allowed"
    when 409
      "Conflict"
    when 422
      "Unprocessable Entity"
    when 401...500
      "Client Error"
    when 500...600
      "Server Error"
    else
      "Unknown"
  end
  response = response_class.new("1.1", code, "Hello World!")
  response.initialize_http_header(header)
  response.stub!(:body).and_return(body)
  response.stub!(:message).and_return(message)
  
  Weary::Response.new(response, request_method)
end

def mock_request(url, method = :get, options={}, mock_header={}, mock_body=nil)
  request = Weary::Request.new(url, method, options)
  request.stub!(:perform).and_return mock_response(method, 200, mock_header, mock_body)
  
  request
end