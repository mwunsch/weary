$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'weary'

class Repository < Weary::Base
  
  def initialize(user, repo)
    self.modify_resource(:show) do |r|
      r.url = "http://github.com/api/v2/yaml/repos/show/#{user}/#{repo}"
    end
  end  
  
  get "show" do |r|
    r.url = "http://github.com/api/v2/yaml/repos/show/__gh_user__/__gh_repo__"
  end
      
end

weary = Repository.new('mwunsch','weary')
puts weary.show.perform.body