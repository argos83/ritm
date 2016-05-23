require 'dot_hash'
require 'set'

module Ritm
  # Global Ritm settings
  class Configuration
    DEFAULT_SETTINGS = {
      proxy: {
        bind_address: '127.0.0.1',
        bind_port: 8080
      },

      ssl_reverse_proxy: {
        bind_address: '127.0.0.1',
        bind_port: 8081,
        ca: {
          pem: nil,
          key: nil
        }
      },

      intercept: {
        # Is interception enabled
        enabled: true,

        # Do not intercept requests whose URLs match/start with the given regex/strings (blacklist)
        skip_urls: [],

        # Intercepts requests whose  URLs match/start with the given regex/strings (whitelist)
        # By default everything will be intercepted.
        intercept_urls: []
      },

      misc: {
        add_request_headers: {},
        add_response_headers: { 'connection' => 'clone' },

        strip_request_headers: [/proxy-*/],
        strip_response_headers: ['strict-transport-security', 'transfer-encoding'],

        unpack_gzip_deflate_in_requests: true,
        unpack_gzip_deflate_in_responses: true,
        process_chunked_encoded_transfer: true
      }
    }.freeze

    def initialize(settings = {})
      settings = DEFAULT_SETTINGS.merge(settings)
      @values = {
        dispatcher: Dispatcher.new,

        # Is interception enabled
        enabled: true
      }

      @settings = settings.to_properties
    end

    def method_missing(m, *args, &block)
      @settings.send(m, *args, &block)
    end

    def [](setting)
      @values[setting]
    end

    # Re-enable interception
    def enable
      @values[:enabled] = true
    end

    # Disable interception
    def disable
      @values[:enabled] = false
    end
  end
end
