module Weary
  class HTTPError < StandardError; end
  
  class RedirectionError < HTTPError; end
  class ClientError      < HTTPError; end
  class ServerError      < HTTPError; end
  
  class BadRequest          < ClientError; end #400
  class Unauthorized        < ClientError; end #401
  class Forbidden           < ClientError; end #403
  class NotFound            < ClientError; end #404
  class MethodNotAllowed    < ClientError; end #405
  class ResourceConflict    < ClientError; end #409
  class UnprocessableEntity < ClientError; end #422  
end