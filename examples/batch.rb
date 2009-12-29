$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'weary'
require 'fakeweb'
require 'pp'

hello = "Hello from"
resources = %w[http://twitter.com http://github.com http://vimeo.com http://tumblr.com]
resources.each {|url| FakeWeb.register_uri :get, url, :body => "#{hello} #{url}" }

requests = []
resources.each do |url|
  requests << Weary.get(url) do |request| 
    request.on_complete { |response| puts response.body } 
  end
end

Weary.batch(requests).perform

FakeWeb.clean_registry