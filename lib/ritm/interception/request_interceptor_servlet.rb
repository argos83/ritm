require 'webrick'
require 'ritm/interception/http_forwarder'

module Ritm
  # Actual implementation of the SSL Reverse Proxy service (decoupled from the certificate handling)
  class RequestInterceptorServlet < WEBrick::HTTPServlet::AbstractServlet
    def initialize(server, request_interceptor, response_interceptor)
      super server
      @forwarder = HTTPForwarder.new(request_interceptor, response_interceptor)
    end

    def service(request, response)
      @forwarder.forward(request, response)
    end
  end
end
