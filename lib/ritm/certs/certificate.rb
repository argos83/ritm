require 'certificate_authority'

module Ritm
  # Wraps a SSL Certificate via on-the-fly creation or loading from files
  class Certificate
    attr_accessor :cert

    def self.load(crt, private_key)
      x509 = OpenSSL::X509::Certificate.new(crt)
      cert = CertificateAuthority::Certificate.from_openssl(x509)
      cert.key_material.private_key = OpenSSL::PKey::RSA.new(private_key)
      yield cert if block_given?
      new cert
    end

    def self.create(common_name, serial_number: nil)
      cert = CertificateAuthority::Certificate.new
      cert.subject.common_name = common_name
      cert.subject.organization = cert.subject.organizational_unit = 'RubyInTheMiddle'
      cert.subject.country = 'AR'
      cert.not_before = cert.not_before - 3600 * 24 * 30 # Substract 30 days
      cert.serial_number.number = serial_number || common_name.hash.abs
      cert.key_material.generate_key(1024)
      yield cert if block_given?
      new cert
    end

    def initialize(cert)
      @cert = cert
    end

    def private_key
      @cert.key_material.private_key
    end

    def public_key
      @cert.key_material.public_key
    end

    def pem
      @cert.to_pem
    end

    def x509
      @cert.openssl_body
    end
  end
end
