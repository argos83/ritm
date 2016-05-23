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
        ca = config[:ca]

        # Keeps track of the created self-signed certificates
        # TODO: this can grow a lot and take up memory, fix by either:
        # 1. implementing wildcard certificates generation (so there's one certificate per top level domain)
        # 2. Use the same key material (private/public keys) for all the server names and just do the signing on-the-fly
        # 3. both of the above
        contexts = {}
        mutex = Mutex.new

        # Sets the SNI callback on the SSLTCPSocket
        ctx.servername_cb = proc { |sock, servername|
          mutex.synchronize do
            unless contexts.include? servername
              cert = Ritm::Certificate.create(servername)
              ca.sign(cert)
              contexts[servername] = context_with_cert(sock.context, cert)
            end
          end
          contexts[servername]
        }
        ctx
      end

      def context_with_cert(original_ctx, cert)
        ctx = OpenSSL::SSL::SSLContext.new
        ctx.key = OpenSSL::PKey::RSA.new(cert.private_key)
        ctx.cert = OpenSSL::X509::Certificate.new(cert.pem)
        ctx.client_ca = original_ctx.client_ca
        ctx.extra_chain_cert = original_ctx.extra_chain_cert
        ctx.ca_file = original_ctx.ca_file
        ctx.ca_path = original_ctx.ca_path
        ctx.cert_store = original_ctx.cert_store
        ctx.verify_mode = original_ctx.verify_mode
        ctx.verify_depth = original_ctx.verify_depth
        ctx.verify_callback = original_ctx.verify_callback
        ctx.timeout = original_ctx.timeout
        ctx.options = original_ctx.options
        ctx
      end
    end
  end
end
