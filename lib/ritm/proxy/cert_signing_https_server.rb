require 'webrick'
require 'webrick/https'
require 'ritm/certs/certificate'

module Ritm
  module Proxy
    # Patches WEBrick::HTTPServer SSL context creation to get
    # a callback on the 'Client Helo' step of the SSL-Handshake if SNI is specified
    # So we can create self-signed certificates on the fly
    class CertSigningHTTPSServer < WEBrick::HTTPServer
      # Override
      def setup_ssl_context(config)
        ctx = super(config)
        prepare_sni_callback(ctx, config[:ca])
        ctx
      end

      private

      # Keeps track of the created self-signed certificates
      # TODO: this can grow a lot and take up memory, fix by either:
      # 1. implementing wildcard certificates generation (so there's one certificate per top level domain)
      # 2. Use the same key material (private/public keys) for all the server names and just do the signing on-the-fly
      # 3. both of the above
      def prepare_sni_callback(ctx, ca)
        contexts = {}
        mutex = Mutex.new

        # Sets the SNI callback on the SSLTCPSocket
        ctx.servername_cb = proc do |sock, servername|
          mutex.synchronize do
            unless contexts.include? servername
              cert = Ritm::Certificate.create(servername)
              ca.sign(cert)
              contexts[servername] = context_with_cert(sock.context, cert)
            end
          end
          contexts[servername]
        end
      end

      def context_with_cert(original_ctx, cert)
        ctx = original_ctx.dup
        ctx.key = OpenSSL::PKey::RSA.new(cert.private_key)
        ctx.cert = OpenSSL::X509::Certificate.new(cert.pem)
        ctx
      end
    end
  end
end
