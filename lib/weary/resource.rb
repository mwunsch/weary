module Weary
  class Resource
    attr_reader :name, :with, :requires, :via, :format, :url
    
    def initialize(name,options={})
      @domain = options[:domain]
      self.name = name
      self.via = options[:via]
      self.with = options[:with]
      self.requires = options[:requires]
      self.format = options[:in_format]
      self.url = options[:construct_url] if options[:url].nil?
      @url = options[:url] unless options[:url].nil?
      @authenticates = (options[:authenticates] != false)
    end
    
    def name=(resource)
      @name = resource.to_s
    end
    
    def via=(verb)
      @via = verb.to_sym
    end
    
    def with=(params)
      if params.empty?
        @with = nil
      else
        @with = params.collect {|x| x.to_sym }
      end
    end
    
    def url=(pattern)
      raise StandardError, "Requires a domain to be set" if @domain.nil?
      pattern = pattern.gsub("<domain>", @domain)
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
      @format = type.to_sym
    end
    
    def authenticates?
      @authenticates
    end
    
    def to_hash
      {@name.to_sym => {:via => @via,
                        :with => @with,
                        :requires => @requires,
                        :authenticates => @authenticates,
                        :in_format => @format,
                        :url => @url}}
    end
    
  end
end