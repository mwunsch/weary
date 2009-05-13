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
require 'weary/base'

module Weary
  
  # Weary::Query quickly performs a :get request on a URL and parses the request
  def self.Query(url)
    req = Weary::Request.new(url, :get).perform
    req.parse
  end
  
end

# req = Weary::Request.new "http://github.com/api/v2/json/user/show/mwunsch"
# doc = Weary::Query "http://github.com/api/v2/xml/user/show/mwunsch"
# 
# pp doc