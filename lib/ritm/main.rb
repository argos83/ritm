# Main module
module Ritm
  # Define global settings
  def self.configure(&block)
    conf.instance_eval(&block)
  end

  # Re-enable fuzzing (if it was disabled)
  def self.enable
    conf.enable
  end

  # Disable fuzzing (if it was enabled)
  def self.disable
    conf.disable
  end

  # Access the current config settings
  def self.conf
    @configuration ||= Configuration.new
  end

  def self.dispatcher
    @dispatcher ||= Dispatcher.new
  end

  def self.add_handler(handler)
    dispatcher.add_handler(handler)
  end

  def self.on_request(&block)
    dispatcher.on_request(&block)
  end

  def self.on_response(&block)
    dispatcher.on_response(&block)
  end
end
