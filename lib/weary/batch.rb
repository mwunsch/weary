module Weary
  class Batch
    
    attr_accessor :requests, :pool, :responses
    
    def initialize(*requests)
      @requests = requests.flatten
    end
    
    def on_complete(&block)
      @on_complete = block if block_given?
      @on_complete
    end
    
    def before_send(&block)
      @before_send = block if block_given?
      @before_send
    end
    
    def perform(&block)
      @on_complete = block if block_given?
      @responses = []
      @pool = []
      before_send.call if before_send
      requests.each {|req| @pool << req.perform! }
      pool.each {|res| @responses << res.value }
      on_complete.call if on_complete
      responses
    end
  end
end