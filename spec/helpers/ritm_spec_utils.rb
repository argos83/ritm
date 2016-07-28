require 'faraday'
require 'httpclient'
require 'helpers/interceptor'

module RitmSpecUtils
  def interceptor
    INTERCEPTOR
  end

  def client(base_url, verify_ssl: false, ca_file: nil)
    Faraday.new(base_url) do |conn|
      conn.adapter :net_http
      conn.ssl[:verify] = verify_ssl
      conn.ssl[:ca_file] = ca_file unless ca_file.nil?
      conn.proxy 'http://localhost:8080'
    end
  end

  def with_proxy(*args)
    proxy = Ritm::Proxy::Launcher.new(*args)
    proxy.start
    yield
  ensure
    proxy.shutdown
  end

  def server_cert_for_url(url, proxy: 'http://localhost:8080')
    c = HTTPClient.new(proxy)
    c.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
    res = c.get(url)
    res.peer_cert
  end
end
