module Weary
  class HTTPVerb
    
    attr_accessor :verb
    
    def initialize(http_verb = :get)
      self.verb = http_verb      
    end
    
    def normalize
      return verb.to_s.strip.downcase.intern
    end
    
    def request_class
      case normalize
        when :get
          Net::HTTP::Get
        when :post
          Net::HTTP::Post
        when :put
          Net::HTTP::Put
        when :delete
          Net::HTTP::Delete
        when :head
          Net::HTTP::Head
        else
          Net::HTTP::Get  
      end
    end
    
  end
end