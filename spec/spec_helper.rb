$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'weary'
require 'spec'
require 'fakeweb'

def get_fixture(filename)
  open(File.join(File.dirname(__FILE__), 'fixtures', "#{filename.to_s}")).read
end

def http_status_message(code)
  message = case code.to_i
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
  [code.to_s,message]
end