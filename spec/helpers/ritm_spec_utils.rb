require 'faraday'
require 'httpclient'
require 'helpers/interceptor'

DEFAULT_PROXY_ADDRESS = 'http://localhost:8080'.freeze

module RitmSpecUtils
  def interceptor
    INTERCEPTOR
  end

  def client(base_url, verify_ssl: false, ca_file: nil, proxy: DEFAULT_PROXY_ADDRESS)
    Faraday.new(base_url) do |conn|
      conn.adapter :net_http
      conn.ssl[:verify] = verify_ssl
      conn.ssl[:ca_file] = ca_file unless ca_file.nil?
      conn.proxy = proxy
    end
  end

  def with_proxy(proxy_port: 7777, ssl_reverse_proxy_port: 7778)
    session = Ritm::Session.new

    session.configure do
      proxy[:bind_port] = proxy_port
      ssl_reverse_proxy[:bind_port] = ssl_reverse_proxy_port
    end
    session.start
    yield session
  ensure
    session.shutdown
  end

  def server_cert_for_url(url, proxy: DEFAULT_PROXY_ADDRESS)
    c = HTTPClient.new(proxy)
    c.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
    res = c.get(url)
    res.peer_cert
  end
end
