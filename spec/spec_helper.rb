begin
  # Try to require the preresolved locked set of gems.
  require File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  # Fall back on doing an unlocked resolve at runtime.
  require "rubygems"
  require "bundler"
  Bundler.setup
end

begin
  require 'weary'
rescue LoadError
  lib_path = File.join(File.dirname(__FILE__), '..', 'lib')
  $LOAD_PATH.unshift lib_path unless $LOAD_PATH.include?(lib_path)
  require 'weary'
end

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
    when 418
      "I'm a teapot"  
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