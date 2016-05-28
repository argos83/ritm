require 'yaml'
require 'time'
require 'ostruct'

require 'ritm'
require 'ritm/proxy/launcher'
require 'ritm/interception/handlers'
require 'ritm/certs/ca'

module Ritm
  # WIP: Create and scan RitM projects
  class Project
    attr_reader :path, :settings

    FILES = {
      config: 'ritm.yml',
      pem: File.join('certs', 'ritm.crt'),
      key: File.join('certs', 'ritm.key'),
      bootstrap: 'bootstrap.rb',
      # Dirs
      certs: 'certs'
    }.freeze

    # Finds a RitM project in the given directories, the current directory, or ~/.ritm
    # Returns a project instance or nil if no project is found in any of the locations
    def self.find(*dir)
      candidates = [*dir, Dir.pwd, File.join(Dir.home, '.ritm')]

      candidates.each do |candidate|
        cfg = File.join(candidate, FILES[:config])
        return new(candidate) if File.file? cfg
      end
      nil
    end

    # Creates a default project directory structure in the given path
    def self.create(path)
      project = new(path)
      project.instance_eval do
        create_dirs
        create_certs
        create_bootstrap
        create_config
      end
      project
    end

    # Instantiates a RitM project with the settings from the given path
    def initialize(path)
      @path = path
      @settings = nil
    end

    # Loads the project settings and builds the proxy server
    # Returns the proxy service instance (not started)
    def configure
      load_settings
      build_proxy
    end

    private

    def load_settings(reload: false)
      return unless @settings.nil? || reload
      @settings = YAML.load_file(abs_path(FILES[:config]))
      load @settings[:bootstrap] if @settings.key? :bootstrap
    end

    def create_dirs
      FileUtils.mkdir_p abs_path(FILES[:certs])
    end

    def create_certs
      ca = Ritm::CA.create
      pem = abs_path(FILES[:pem])
      key = abs_path(FILES[:key])
      File.write(pem, ca.pem)
      File.write(key, ca.private_key)
    end

    def create_bootstrap
      bootstrap = <<EOF
puts 'test'
EOF
      File.write(abs_path(FILES[:bootstrap]), bootstrap)
    end

    def create_config
      settings = {
        proxy: {
          bind_address: '127.0.0.1',
          bind_port: 8080
        },

        ssl_reverse_proxy: {
          bind_address: '127.0.0.1',
          bind_port: 8081,
          ca: {
            pem: abs_path(FILES[:pem]),
            key: abs_path(FILES[:key])
          }
        },

        intercept: {
          enabled: true,
          skip_urls: [],
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
        },
        bootstrap: abs_path(FILES[:bootstrap])
      }
      File.write(abs_path(FILES[:config]), settings.to_yaml)
    end

    def abs_path(*sub_path)
      File.join(@path, *sub_path)
    end

    def build_proxy
      Ritm::Proxy::Launcher.new
    end
  end
end
