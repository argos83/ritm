require_relative 'spec_helper'
require 'uri'
require 'json'
require 'ritm'
require 'helpers/ritm_spec_utils'

RSpec.describe Ritm do
  include RitmSpecUtils

  let(:base_url) { 'https://127.0.0.1.xip.io:4443/' }
  let(:one_day) { 3600 * 24 }
  let(:ninety_days) { one_day * 90 }

  before(:each) do
    interceptor.clear
    Ritm.conf.misc.ssl_pass_through.clear
  end

  it 'self-signs certificates that are not supported by default' do
    expect { client(base_url, verify_ssl: true).get('/ping') }.to raise_error(Faraday::SSLError)
  end

  it 'does not trigger ssl errors if the CA is trusted' do
    c = client(base_url, verify_ssl: true, ca_file: 'spec/resources/insecure_ca.crt')
    response = c.get('/ping')
    expect(response.body).to eq('pong')
  end

  it 'issues valid certificates signed by the CA' do
    cert = server_cert_for_url(base_url)
    # Main attributes
    expect(cert.subject.to_s). to eq('/CN=127.0.0.1.xip.io/O=RubyInTheMiddle/OU=RubyInTheMiddle/C=AR')
    expect(cert.version).to be 2
    expect(cert.signature_algorithm).to eq('sha512WithRSAEncryption')
    expect(cert.serial.to_s).to eq('127.0.0.1.xip.io'.hash.abs.to_s)
    # Not expired
    expect(cert.not_before).to be < (Time.now - one_day)
    expect(cert.not_after).to be > (Time.now + ninety_days)
    # Extensions
    extensions = cert.extensions.each_with_object({}) { |e, h| h[e.oid] = e.value }
    expect(extensions['keyUsage']).to eq('Digital Signature, Key Encipherment')
    expect(extensions['extendedKeyUsage']).to eq('TLS Web Server Authentication, TLS Web Client Authentication')
    expect(extensions['basicConstraints']).to eq('CA:FALSE')
    # Issuer
    expect(extensions['authorityKeyIdentifier'])
      .to eq("keyid:B1:7B:8A:53:DB:01:1B:F1:51:03:61:AC:21:C7:36:D7:CE:15:BD:08\n")
    expect(cert.issuer.to_s).to eq('/CN=RubyInTheMiddle/O=RubyInTheMiddle/OU=RubyInTheMiddle/C=AR')
  end

  it 'generates a new CA if it was not specified' do
    issuer1 = issuer2 = nil

    with_proxy(proxy_port: 6666, ssl_reverse_proxy_port: 6667) do
      cert = server_cert_for_url(base_url, proxy: 'http://localhost:6666')
      issuer1 = cert.extensions.find { |e| e.oid == 'authorityKeyIdentifier' }.value
    end
    with_proxy(proxy_port: 7777, ssl_reverse_proxy_port: 7778) do
      cert = server_cert_for_url(base_url, proxy: 'http://localhost:7777')
      issuer2 = cert.extensions.find { |e| e.oid == 'authorityKeyIdentifier' }.value
    end

    expect(issuer1).not_to eq(issuer2)
  end

  it 'bypasses proxy if server address matches a pass-through string setting' do
    Ritm.conf.misc.ssl_pass_through << '127.0.0.1.xip.io:4443'
    client(base_url).get('/ping')
    expect(interceptor.requests.size).to be 0
  end

  it 'bypasses proxy if server address matches a pass-through regex setting' do
    Ritm.conf.misc.ssl_pass_through << /.+:4443/
    client(base_url).get('/ping')
    expect(interceptor.requests.size).to be 0
  end

  it ' does not bypass proxy if server address no pass-through settings are matched' do
    Ritm.conf.misc.ssl_pass_through.concat [/.+:4444/, '127.0.0.2.xip.io:4443', /.*ioa:4443/]
    client(base_url).get('/ping')
    expect(interceptor.requests.size).to be 1
  end
end
