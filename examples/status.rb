require File.join(File.dirname(__FILE__), '..', 'lib', 'weary')
require 'pp'

class Status
  extend Weary
  
  on_domain 'http://twitter.com/statuses/'
  format = :json
  
  get "user_timeline",
      :requires => [:id],
      :with => [:user_id, :screen_name, :since_id, :max_id, :count, :page]
  
end

toots = Status.new
recent_toot = toots.user_timeline(:id => "markwunsch", :count => 1).parse
puts "@" + recent_toot[0]["user"]["screen_name"] + ": " + "\"#{recent_toot[0]['text']}\""