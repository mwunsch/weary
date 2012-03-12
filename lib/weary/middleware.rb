module Weary
  module Middleware
    autoload :BasicAuth, 'weary/middleware/basic_auth'
    autoload :OAuth, 'weary/middleware/oauth'
    autoload :ContentType, 'weary/middleware/content_type'
  end
end


