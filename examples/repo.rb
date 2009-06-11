require File.join(File.dirname(__FILE__), '..', 'lib', 'weary')

class Repository
  extend Weary
  
  @gh_user = "mwunsch"
  @gh_repo = "weary"
  
  on_domain "http://github.com/api/v2/"
  as_format :yaml
  
  get "show" do |r|
    r.url = "<domain><format>/repos/show/#{@gh_user}/#{@gh_repo}"
  end
  
  get "network" do |r|
    r.url = "<domain><format>/repos/show/#{@gh_user}/#{@gh_repo}/network"
  end
      
end

weary = Repository.new
puts weary.show.body