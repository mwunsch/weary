require 'pp'
require 'uri'
require 'net/http'
require 'net/https'
require 'rubygems'

gem 'crack'
gem 'nokogiri'

autoload :Yaml, 'yaml'
autoload :Crack, 'crack'
autoload :Nokogiri, 'nokogiri'

require 'weary/core_extensions'
require 'weary/request'
require 'weary/response'
require 'weary/document'
require 'weary/base'

module Weary
  
  # Weary#Document returns an instance of Weary::Document that has been parsed
  def self.Document(doc, type)
    Weary::Document.new(doc, type).parse
  end
  
  # Weary::Query quickly performs a :get request on a URL and parses the request
  def self.Query(url)
    req = Weary::Request.new(url, :get).perform
    Weary::Document(req.body, req.format)
  end
  
end

req = Weary::Request.new "http://github.com/api/v2/json/user/show/mwunsch"
res = req.perform.handle.parse
doc = Weary::Query "http://github.com/api/v2/xml/user/show/mwunsch"

pp doc