require 'ritm/version'
require 'ritm/dispatcher'
require 'ritm/configuration'

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
    conf[:dispatcher]
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

  # private class methods

  def self.intercept?(request)
    return false unless conf[:enabled]
    url = request.url.to_s
    whitelisted?(url) && !blacklisted?(url)
  end

  def self.whitelisted?(url)
    conf[:attack_urls].empty? || url_matches_any?(url, conf[:attack_urls])
  end

  def self.blacklisted?(url)
    url_matches_any? url, conf[:skip_urls]
  end

  def self.url_matches_any?(url, matchers)
    matchers.each do |matcher|
      case matcher
      when Regexp
        return true if url =~ matcher
      when String
        return true if url.include? matcher
      else
        raise 'URL matcher should be a String or Regexp'
      end
    end
    false
  end

  private_class_method :intercept?, :whitelisted?, :blacklisted?, :url_matches_any?
end
