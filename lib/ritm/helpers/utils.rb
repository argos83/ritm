
module Ritm
  # Shortcuts and other utilities to be included
  # in modules/classes
  module Utils
    # Runs a block of code without warnings.
    def self.silence_warnings
      warn_level = $VERBOSE
      $VERBOSE = nil
      result = yield
      $VERBOSE = warn_level
      result
    end
  end
end
