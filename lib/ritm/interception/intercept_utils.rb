require 'ritm/helpers/encodings'

module Ritm
  # Interceptor callbacks calling logic shared by the HTTP Proxy Server and the SSL Reverse Proxy Server
  # Passes request
  module InterceptUtils
    def intercept_request(handler, request)
      return if handler.nil?
      handler.call(request)
    end

    def intercept_response(handler, request, response)
      return if handler.nil?
      # TODO: Disable the automated decoding from config
      encoding = content_encoding(response)
      decoded(encoding, response) do |decoded_response|
        handler.call(request, decoded_response)
      end

      response.header.delete('content-length') if chunked?(response)
    end

    private

    def chunked?(response)
      response.header.fetch('transfer-encoding', '').casecmp 'chunked'
    end

    def content_encoding(response)
      case response.header.fetch('content-encoding', '').downcase
      when 'gzip', 'x-gzip'
        :gzip
      when 'deflate'
        :deflate
      else
        :identity
      end
    end

    def decoded(encoding, res)
      res.body = Encodings.decode(encoding, res.body)
      _content_encoding = res.header.delete('content-encoding')
      yield res
      # TODO: should it be re-encoded?
      # res.body = Encodings.encode(encoding, res.body)
      # res.header['content-encoding'] = content_encoding
      res.header['content-length'] = res.body.size.to_s
    end
  end
end
