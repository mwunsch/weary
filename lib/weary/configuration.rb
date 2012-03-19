module Weary
  module Configuration
    # Which adapter you want. Defaults to Weary::Adapter::NetHttp
    attr_accessor :adapter

    # Yield self to be able to configure Weary with block-style configuration.
    #
    # Example:
    #
    #   Weary.configure do |configuration|
    #     configuration.adapter = Weary::Adapter::Excon
    #   end
    def configure
      yield self
    end

    # Set intelligent default
    def adapter
      @adapter || Weary::Adapter::NetHttp
    end
  end
end
