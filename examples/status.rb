$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'weary'
require 'pp'

class Status < Weary::Base
  
  domain "http://twitter.com/statuses/"
  
  get "user_timeline" do |resource|
    resource.requires = [:id]
    resource.with = [:user_id, :screen_name, :since_id, :max_id, :count, :page]
  end
  
end

toots = Status.new

toots.user_timeline(:id => "markwunsch").perform do |response|
  if response.success?
    recent_toot = response[0]
    puts "@#{recent_toot['user']['screen_name']}: \"#{recent_toot['text']}\""
  else
   puts "#{response.code}: #{response.message}"
 end
end