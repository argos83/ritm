require 'webrick'
require 'webrick/httpproxy'
require 'ritm/helpers/utils'

# Patch WEBrick too short max uri length
Ritm::Utils.silence_warnings { WEBrick::HTTPRequest::MAX_URI_LENGTH = 4000 }

# Make request method writable
WEBrick::HTTPRequest.instance_eval { attr_accessor :request_method, :unparsed_uri }

module WEBrick
  # Other patches to WEBrick::HTTPRequest
  class HTTPRequest
    def []=(header_name, *values)
      @header[header_name.downcase] = values.map(&:to_s)
    end

    def body=(str)
      body # Read current body
      @body = str
    end

    def request_uri=(uri)
      @request_uri = parse_uri(uri.to_s)
    end
  end

  # Support other methods in HTTPServer
  class HTTPServer
    def do_DELETE(req, res)
      perform_proxy_request(req, res) do |http, path, header|
        http.delete(path, header)
      end
    end

    def do_PUT(req, res)
      perform_proxy_request(req, res) do |http, path, header|
        http.put(path, req.body || '', header)
      end
    end

    def do_PATCH(req, res)
      perform_proxy_request(req, res) do |http, path, header|
        http.patch(path, req.body || '', header)
      end
    end

    # TODO: make sure options gets proxied too (so trace)
    def do_OPTIONS(_req, res)
      res['allow'] = 'GET,HEAD,POST,PUT,PATCH,DELETE,OPTIONS,CONNECT'
    end
  end
end
