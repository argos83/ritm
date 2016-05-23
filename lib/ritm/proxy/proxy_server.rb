require 'webrick'
require 'webrick/httpproxy'
require 'ritm/helpers/patches'
require 'ritm/interception/intercept_utils'

module Ritm
  module Proxy
    # Proxy server that accepts request and response intercept handlers for HTTP traffic
    # HTTPS traffic is redirected to the SSLReverseProxy for interception
    class ProxyServer < WEBrick::HTTPProxyServer
      include InterceptUtils

      def start_async
        trap(:TERM) { shutdown }
        trap(:INT) { shutdown }
        Thread.new { start }
      end

      # Override
      # Patches the destination address on HTTPS connections to go via the HTTPS Reverse Proxy
      def do_CONNECT(req, res)
        req.class.send(:attr_accessor, :unparsed_uri)
        req.unparsed_uri = @config[:https_forward]
        super
      end

      # Override
      # Handles HTTP (no SSL) traffic interception
      def proxy_service(req, res)
        # Proxy Authentication
        proxy_auth(req, res)

        # Request modifier handler
        intercept_request(@config[:request_interceptor], req)

        begin
          send("do_#{req.request_method}", req, res)
        rescue NoMethodError
          raise WEBrick::HTTPStatus::MethodNotAllowed,
                "unsupported method `#{req.request_method}'."
        rescue => err
          logger.debug("#{err.class}: #{err.message}")
          raise WEBrick::HTTPStatus::ServiceUnavailable, err.message
        end

        # Response modifier handler
        intercept_response(@config[:response_interceptor], req, res)
      end
    end
  end
end
