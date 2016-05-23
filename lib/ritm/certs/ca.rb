require 'certificate_authority'
require 'ritm/certs/certificate'

module Ritm
  # Wrapper on a Certificate Authority with ability of signing certificates
  class CA < Ritm::Certificate
    def self.create(common_name: 'RubyInTheMiddle')
      super(common_name, serial_number: 1) do |cert|
        cert.signing_entity = true
        cert.sign!(signing_profile)
        yield cert if block_given?
      end
    end

    def self.load(crt, private_key)
      super(crt, private_key) do |cert|
        cert.signing_entity = true
        cert.sign!(signing_profile)
        yield cert if block_given?
      end
    end

    def sign(certificate)
      certificate.cert.parent = @cert
      certificate.cert.sign!
    end

    def self.signing_profile
      { 'extensions' => { 'keyUsage' => { 'usage' => %w(critical keyCertSign keyEncipherment digitalSignature) } } }
    end
  end
end
