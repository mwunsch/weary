module Weary
  class Resource
    attr_reader :name, :with, :requires
    attr_accessor :via, :format
    # :name, :via, :with, :requires, :authenticates, :in_format, :url
    def initialize(name,options={})
      self.name = name
      self.via = options[:via].to_sym
      self.with = options[:with]
      self.requires = options[:requires]
      self.format = options[:in_format].to_sym
      @authenticates = (options[:authenticates] != false)
    end
    
    def name=(resource)
      string = resource.to_s
      @name = string
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