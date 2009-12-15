module Weary
  class Batch
    
    attr_accessor :requests
    
    def initialize(*requests)
      @requests = requests.flatten
    end
    
  end
end