require 'net/http'
require 'openssl'
require 'webrick'
require 'webrick/https'
require 'ritm/certs/certificate'

IS_RUBY_2_4_OR_OLDER = Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.4')

module Ritm
  module Proxy
    # Patches WEBrick::HTTPServer SSL context creation to get
    # a callback on the 'Client Helo' step of the SSL-Handshake if SNI is specified
    # So RitM can create self-signed certificates on the fly
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
              begin
                cert = fetch_remote_cert(servername)
              rescue StandardError
                cert = Ritm::Certificate.create(servername)
              end
              ca.sign(cert)
              contexts[servername] = context_with_cert(sock.context, cert)
            end
          end
          contexts[servername]
        end
      end

      def context_with_cert(original_ctx, cert)
        ctx = duplicate_context(original_ctx)
        ctx.key = cert.private_key
        ctx.cert = cert.x509
        ctx
      end

      def duplicate_context(original_ctx)
        return original_ctx.dup unless IS_RUBY_2_4_OR_OLDER

        ctx = OpenSSL::SSL::SSLContext.new

        original_ctx.instance_variables.each do |variable_name|
          prop_name = variable_name.to_s.sub(/^@/, '')
          set_prop_method = "#{prop_name}="
          ctx.send(set_prop_method, original_ctx.send(prop_name)) if ctx.respond_to? set_prop_method
        end
        ctx
      end

      def fetch_remote_cert(servername)
        host = servername.gsub( "*.", "www." )
        x509_cert = Net::HTTP.start(
          host,
          '443', use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE,
          &:peer_cert
        )
        Ritm::Certificate.new(CertificateAuthority::Certificate.from_openssl(x509_cert))
      end
    end
  end
end

