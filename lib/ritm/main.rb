require 'ritm/session'

# Main module
module Ritm
  GLOBAL_SESSION = Session.new

  def self.method_missing(m, *args, &block)
    if GLOBAL_SESSION.respond_to?(m)
      GLOBAL_SESSION.send(m, *args, &block)
    else
      super
    end
  end

  def self.respond_to_missing?(method_name, _include_private = false)
    GLOBAL_SESSION.respond_to?(method_name) || super
  end
end
