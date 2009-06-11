require File.join(File.dirname(__FILE__), '..', 'lib', 'weary')
require 'pp'

class Test
  extend Weary
  
  on_domain "http://twitter.com/statuses/"
  
  declare "user_timeline" do |resource|
    resource.requires = [:id]
    resource.with = [:user_id, :screen_name, :since_id, :max_id, :count, :page]
  end
    
end

pp Test.resources