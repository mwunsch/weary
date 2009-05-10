class Response
  def initialize(http_response)
    puts http_response.is_a?(Net::HTTPResponse)
  end
end