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
        req.unparsed_uri = @config[:https_forward] unless ssl_pass_through? req.unparsed_uri
        super
      end

      # Override
      # Handles HTTP (no SSL) traffic interception
      def proxy_service(req, res)
        # Proxy Authentication
        proxy_auth(req, res)

        # Request modifier handler
        intercept_request(@config[:request_interceptor], req, @config[:ritm_conf].intercept.request)

        begin
          send("do_#{req.request_method}", req, res)
        rescue NoMethodError
          raise WEBrick::HTTPStatus::MethodNotAllowed, "unsupported method `#{req.request_method}'."
        rescue StandardError => err
          raise WEBrick::HTTPStatus::ServiceUnavailable, err.message
        end

        # Response modifier handler
        intercept_response(@config[:response_interceptor], req, res, @config[:ritm_conf].intercept.response)
      end

      # Override
      def proxy_uri(req, _res)
        if req.request_method == 'CONNECT'
          # Let the reverse proxy handle upstream proxies for https
          nil
        else
          proxy = @config[:ritm_conf].misc.upstream_proxy
          proxy.nil? ? nil : URI.parse(proxy)
        end
      end

      private

      def ssl_pass_through?(destination)
        @config[:ritm_conf].misc.ssl_pass_through.each do |matcher|
          case matcher
          when String
            return true if destination == matcher
          when Regexp
            return true if destination =~ matcher
          end
        end
        false
      end
    end
  end
end
