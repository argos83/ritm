require 'faraday'
require 'helpers/interceptor'

module RitmSpecUtils
  def interceptor
    INTERCEPTOR
  end

  def client(base_url)
    Faraday.new(base_url) do |conn|
      conn.adapter :net_http
      conn.ssl[:verify] = false
      conn.proxy 'http://localhost:8080'
    end
  end
end
