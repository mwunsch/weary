module Weary
  class Batch
    
    attr_accessor :requests, :pool, :responses
    
    def initialize(*requests)
      @requests = requests.flatten
    end
    
     # A callback that is triggered after all the Responses have been received.
    def on_complete(&block)
      @on_complete = block if block_given?
      @on_complete
    end
    
    # A callback that is triggered before the Requests are performed
    def before_send(&block)
      @before_send = block if block_given?
      @before_send
    end
    
    # Perform each Request in a separate Thread. 
    # The Threads are collected in `pool`.
    # The Responses are collected in `responses`.
    # Pass in a block to use as the on_complete callback.
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