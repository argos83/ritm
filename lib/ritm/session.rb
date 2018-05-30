require 'ritm/dispatcher'
require 'ritm/proxy/launcher'
require 'ritm/configuration'

module Ritm
  # Holds the context of a interception session.
  # Changes in the context configuration should affect only this session
  class Session
    attr_reader :conf, :dispatcher

    def initialize
      @conf = Configuration.new
      @dispatcher = Dispatcher.new
      @proxy = nil
    end

    # Define configuration settings
    def configure(&block)
      conf.instance_eval(&block)
    end

    # Re-enable fuzzing (if it was disabled)
    def enable
      conf.enable
    end

    # Disable fuzzing (if it was enabled)
    def disable
      conf.disable
    end

    # Start the proxy service
    def start
      raise 'Proxy already started' unless @proxy.nil?
      @proxy = Proxy::Launcher.new(self)
      @proxy.start
    end

    # Shutdown the proxy service
    def shutdown
      @proxy.shutdown unless @proxy.nil?
      @proxy = nil
    end

    def add_handler(handler)
      dispatcher.add_handler(handler)
    end

    def on_request(&block)
      dispatcher.on_request(&block)
    end

    def on_forward(&block)
      dispatcher.on_forward(&block)
    end

    def on_response(&block)
      dispatcher.on_response(&block)
    end
  end
end
