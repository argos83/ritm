require 'ritm/helpers/encodings'

module Ritm
  # Interceptor callbacks calling logic shared by the HTTP Proxy Server and the SSL Reverse Proxy Server
  module InterceptUtils
    def intercept_request(handler, request, intercept_request_settings)
      return if handler.nil?
      preprocess(request, intercept_request_settings)
      handler.call(request)
      postprocess(request, intercept_request_settings)
    end

    def intercept_forward(handler, request, response, &block)
      return if handler.nil?
      handler.call(request, response, &block)
    end

    def intercept_response(handler, request, response, intercept_response_settings)
      return if handler.nil?
      preprocess(response, intercept_response_settings)
      handler.call(request, response)
      postprocess(response, intercept_response_settings)
    end

    private

    def preprocess(req_res, settings)
      headers = header_obj(req_res)
      decode(req_res) if settings.unpack_gzip_deflate
      req_res.header.delete_if { |name, _v| strip?(name, settings.strip_headers) }
      settings.add_headers.each { |name, value| headers[name] = value }
      req_res.header.delete('transfer-encoding') if chunked?(headers)
    end

    def postprocess(req_res, settings)
      header_obj(req_res)['content-length'] = (req_res.body || '').bytesize.to_s if settings.update_content_length
    end

    def chunked?(headers)
      headers['transfer-encoding'] && headers['transfer-encoding'].casecmp('chunked')
    end

    def content_encoding(req_res)
      ce = header_obj(req_res)['content-encoding'] || ''
      case ce.downcase
      when 'gzip', 'x-gzip'
        :gzip
      when 'deflate'
        :deflate
      else
        :identity
      end
    end

    def header_obj(req_res)
      case req_res
      when WEBrick::HTTPRequest
        req_res
      when WEBrick::HTTPResponse
        req_res.header
      end
    end

    def decode(req_res)
      encoding = content_encoding(req_res)
      return if encoding == :identity

      req_res.body = Encodings.decode(encoding, req_res.body)
      req_res.header.delete('content-encoding')
      headers = header_obj(req_res)
      headers['content-length'] = (req_res.body || '').bytesize.to_s
    end

    def strip?(header, rules)
      header = header.to_s.downcase
      rules.each do |rule|
        case rule
        when String
          return true if header == rule
        when Regexp
          return true if header =~ rule
        end
      end
      false
    end
  end
end
