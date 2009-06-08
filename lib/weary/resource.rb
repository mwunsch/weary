module Weary
  class Resource
    attr_reader :name, :with, :requires, :via, :format, :url
    
    def initialize(name,options={})
      @domain = options[:domain]
      self.name = name
      self.via = options[:via]
      self.with = options[:with]
      self.requires = options[:requires]
      self.format = options[:format]
      self.url = options[:url]
      @authenticates = (options[:authenticates] != false)
      @follows = (options[:no_follow] == false)
    end
    
    def name=(resource)
      @name = resource.to_s
    end
    
    def via=(verb)
      @via = verb
    end
    
    def with=(params)
      if params.empty?
        @with = nil
      else
        @with = params.collect {|x| x.to_sym }
      end
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
    
    def requires=(params)
      if (params.nil? || params.empty?)
        @requires = nil
      else
        @requires = params
      end
    end
    
    def format=(type)
      @format = type
    end
    
    def authenticates?
      @authenticates
    end
    
    def follows_redirects?
      @follows
    end
    
    def to_hash
      {@name.to_sym => {:via => @via,
                        :with => @with,
                        :requires => @requires,
                        :authenticates => authenticates?,
                        :format => @format,
                        :url => @url},
                        :no_follow => !follows_redirects?}
    end
    
  end
end