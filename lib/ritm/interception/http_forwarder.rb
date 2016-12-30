require 'faraday'

require 'ritm/interception/intercept_utils'

module Ritm
  # Forwarder that acts as a WEBrick <-> Faraday adaptor: Works this way:
  #  1. A WEBrick request objects is received
  #  2. The WEBrick request object is sent to the request interceptor
  #  3. The (maybe modified) WEBrick request object is transformed into a Faraday request and sent to destination server
  #  4. The Faraday response obtained from the server is transformed into a WEBrick response
  #  5. The WEBrick response object is sent to the response interceptor
  #  6. The (maybe modified) WEBrick response object is sent back to the client
  #
  # Besides the possible modifications to be done by interceptors there might be automated globally configured
  # transformations like header stripping/adding.
  class HTTPForwarder
    include InterceptUtils

    def initialize(request_interceptor, response_interceptor, context_config)
      @request_interceptor = request_interceptor
      @response_interceptor = response_interceptor
      @config = context_config
      # TODO: make SSL verification a configuration setting
      @client = Faraday.new(ssl: { verify: false }) do |conn|
        conn.adapter :net_http
        conn.proxy @config.misc.upstream_proxy unless @config.misc.upstream_proxy.nil?
      end
    end

    def forward(request, response)
      intercept_request(@request_interceptor, request, @config.intercept.request)
      faraday_response = faraday_forward request
      to_webrick_response faraday_response, response
      intercept_response(@response_interceptor, request, response, @config.intercept.response)
    end

    private

    def faraday_forward(request)
      req_method = request.request_method.downcase
      @client.send req_method do |req|
        req.url request.request_uri
        req.body = request.body
        request.header.each do |name, value|
          req.headers[name] = value
        end
      end
    end

    def to_webrick_response(faraday_response, webrick_response)
      webrick_response.status = faraday_response.status
      webrick_response.body = faraday_response.body
      faraday_response.headers.each do |name, value|
        webrick_response[name] = value
      end
      webrick_response
    end
  end
end
