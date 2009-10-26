module Weary
  class HTTPVerb
    
    attr_accessor :verb
    
    def initialize(http_verb = :get)
      self.verb = http_verb      
    end
    
    def normalize
      return verb.to_s.strip.downcase.intern
    end
    
  end
end