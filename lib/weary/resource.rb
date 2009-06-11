module Weary
  class Resource
    attr_accessor :name, :domain, :with, :requires, :via, :format, :url, :authenticates, :follows
    
    def initialize(name)
      self.name = name
      self.via = :get
      self.authenticates = false
      self.follows = true
      self.with = []
      self.requires
    end
        
    def with=(params)
      unless @requires.nil?
        @with = params.collect {|x| x.to_sym} | @requires
      else
        @with = params.collect {|x| x.to_sym}
      end
    end
    
    def requires=(params)
      @with = @with | params.collect {|x| x.to_sym}
      @requires = params.collect {|x| x.to_sym}
    end
    
    def url=(pattern)
      if pattern.index("<domain>")
        raise StandardError, "Domain flag found but the domain is not defined" if @domain.nil?
        pattern = pattern.gsub("<domain>", @domain)
      end
      pattern = pattern.gsub("<resource>", @name)
      pattern = pattern.gsub("<format>", @format.to_s)
      @url = pattern
    end

    def authenticates?
      @authenticates
    end
    
    def follows_redirects?
      @follows
    end

    def to_hash
      {@name.to_sym => { :via => @via,
                         :with => @with,
                         :requires => @requires,
                         :follows => @follows,
                         :authenticates => @authenticates,
                         :format => @format,
                         :url => @url,
                         :domain => @domain}}
    end
    
  end
end