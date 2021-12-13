require 'dot_hash'
require 'set'

module Ritm
  class Configuration
    def default_settings # rubocop:disable Metrics/MethodLength
      {
        proxy: {
          bind_address: '127.0.0.1',
          bind_port: 8080,
          auth_proc: Proc.new do |req, res|
            WEBrick::HTTPAuth.proxy_basic_auth(req, res, 'proxy') do |user, pass|
              user == "user" && pass == "pass"
            end
          end
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
          enabled: true,
          request: {
            add_headers: {},
            strip_headers: [/proxy-*/],
            unpack_gzip_deflate: true,
            update_content_length: true
          },
          response: {
            add_headers: { 'connection' => 'close' },
            strip_headers: ['strict-transport-security'],
            unpack_gzip_deflate: true,
            update_content_length: true
          },
          process_chunked_encoded_transfer: true
        },

        misc: {
          ssl_pass_through: [],
          upstream_proxy: nil
        }
      }
    end

    def initialize
      reset
    end

    def reset
      @settings = default_settings.to_properties
    end

    def method_missing(m, *args, &block)
      if @settings.respond_to?(m)
        @settings.send(m, *args, &block)
      else
        super
      end
    end

    def enable
      @settings.intercept[:enabled] = true
    end

    def disable
      @settings.intercept[:enabled] = false
    end

    def respond_to_missing?(method_name, _include_private = false)
      @settings.respond_to?(method_name) || super
    end
  end
end
