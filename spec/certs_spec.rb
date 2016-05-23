require_relative 'spec_helper'
require 'ritm/certs/certificate'
require 'ritm/certs/ca'

describe Ritm::Certificate do
  let(:a_common_name) { 'testcert.example.com' }
  let(:a_serial_number) { 123 }
  let(:a_cert) { Ritm::Certificate.create(a_common_name, serial_number: a_serial_number) }
  let(:cert_a) { Ritm::Certificate.create('testcert.example.com') }
  let(:cert_b) { Ritm::Certificate.create('testcert.example.com') }

  it 'can create unsigned certificates with attributes' do
    expect(a_cert.cert.serial_number.number).to eq(a_serial_number)
    expect(a_cert.cert.distinguished_name.common_name).to eq(a_common_name)
    expect(a_cert.public_key.to_s).to start_with("-----BEGIN PUBLIC KEY-----\n")
    expect(a_cert.private_key.to_s).to start_with("-----BEGIN RSA PRIVATE KEY-----\n")
  end

  it 'creates a different cert every time' do
    expect(cert_a.public_key.to_s).not_to eq(cert_b.public_key.to_s)
    expect(cert_a.private_key.to_s).not_to eq(cert_b.private_key.to_s)
  end

  it 'can make up serial numbers' do
    expect(cert_a.cert.serial_number.number).to be('testcert.example.com'.hash.abs)
  end
end

describe Ritm::CA do
  let(:a_ca) { Ritm::CA.create }
  let(:a_cert) { Ritm::Certificate.create 'www.example.com' }
  let(:pem_file) { File.read(test_path('resources/insecure_ca.crt')) }
  let(:key_file) { File.read(test_path('resources/insecure_ca.priv')) }

  it 'can create certification authorities' do
    expect(a_ca.cert.serial_number.number).to be(1)
    expect(a_ca.cert.distinguished_name.common_name).to eq('RubyInTheMiddle')
    expect(a_ca.cert.extensions['keyUsage'].usage).to include('critical', 'keyCertSign',
                                                              'keyEncipherment', 'digitalSignature')
    expect(a_ca.cert.is_signing_entity?).to be true
    expect(a_ca.pem).to start_with("-----BEGIN CERTIFICATE-----\n")
  end

  it 'can sign certificates' do
    expect { a_cert.pem }.to raise_error(RuntimeError, 'Certificate has no signed body')
    a_ca.sign(a_cert)

    expect(a_cert.pem).to start_with("-----BEGIN CERTIFICATE-----\n")
    expect(a_cert.cert.parent.distinguished_name.common_name).to eq('RubyInTheMiddle')
  end

  it 'can be initialized from a pem and a private key file' do
    ca = Ritm::CA.load(pem_file, key_file)

    expect(ca.cert.serial_number.number).to be(1)
    expect(ca.cert.is_signing_entity?).to be true
    expect(ca.cert.parent.distinguished_name.common_name).to eq('RubyInTheMiddle')
    expect(ca.cert.extensions['keyUsage'].usage).to include('critical', 'keyCertSign',
                                                            'keyEncipherment', 'digitalSignature')
    expect(ca.pem).to eq(pem_file)
    expect(ca.private_key.to_s).to eq(key_file)
  end
end
