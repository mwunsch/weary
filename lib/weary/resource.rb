module Weary
  class Resource
    attr_reader :name, :with, :requires, :via, :format
    
    def initialize(name,options={})
      self.name = name
      self.via = options[:via]
      self.with = options[:with]
      self.requires = options[:requires]
      self.format = options[:in_format]
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
        @with = params
      end
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
                        :in_format => @format}}
    end
    
  end
end