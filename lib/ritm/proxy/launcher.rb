require 'ritm/proxy/ssl_reverse_proxy'
require 'ritm/proxy/proxy_server'
require 'ritm/certs/ca'
require 'ritm/interception/handlers'
require 'ritm/interception/http_forwarder'

module Ritm
  module Proxy
    # Launches the Proxy server and the SSL Reverse Proxy with the given settings
    class Launcher
      def initialize(session)
        build_settings(session)
        build_reverse_proxy
        build_proxy
      end

      def start
        @https.start_async
        @http.start_async
      end

      def shutdown
        @https.shutdown
        @http.shutdown
      end

      private

      def build_settings(session)
        @conf = session.conf
        ssl_proxy_host = @conf.ssl_reverse_proxy.bind_address
        ssl_proxy_port = @conf.ssl_reverse_proxy.bind_port
        @https_forward = "#{ssl_proxy_host}:#{ssl_proxy_port}"

        request_interceptor = default_request_handler(session)
        forward_interceptor = default_forward_handler(session)
        response_interceptor = default_response_handler(session)
        @forwarder = HTTPForwarder.new(request_interceptor, forward_interceptor, response_interceptor, @conf)

        crt_path = @conf.ssl_reverse_proxy.ca.pem
        key_path = @conf.ssl_reverse_proxy.ca.key
        @certificate = ca_certificate(crt_path, key_path)
      end

      def build_proxy
        @http = Ritm::Proxy::ProxyServer.new(BindAddress: @conf.proxy.bind_address,
                                             Port: @conf.proxy.bind_port,
                                             AccessLog: [],
                                             Logger: WEBrick::Log.new(File.open(File::NULL, 'w')),
                                             https_forward: @https_forward,
                                             ProxyVia: nil,
                                             forwarder: @forwarder,
                                             ritm_conf: @conf)
      end

      def build_reverse_proxy
        @https = Ritm::Proxy::SSLReverseProxy.new(@conf.ssl_reverse_proxy.bind_port,
                                                  @certificate,
                                                  @forwarder)
      end

      def ca_certificate(pem, key)
        if pem.nil? || key.nil?
          Ritm::CA.create
        else
          Ritm::CA.load(File.read(pem), File.read(key))
        end
      end
    end
  end
end
