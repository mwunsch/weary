require File.join(File.dirname(__FILE__), '..', 'lib', 'weary')

class Status
  extend Weary
  
  on_domain "http://twitter.com/statuses/"
  
  get "user_timeline" do |resource|
    resource.requires = [:id]
    resource.with = [:user_id, :screen_name, :since_id, :max_id, :count, :page]
  end
  
end

toots = Status.new
recent_toot = toots.user_timeline(:id => "markwunsch", :count => 1).parse
puts "@" + recent_toot[0]["user"]["screen_name"] + ": " + "\"#{recent_toot[0]['text']}\""