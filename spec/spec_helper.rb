TESTS_DIR = File.dirname(__FILE__)
PROJECT_DIR = File.join(TESTS_DIR, '..', 'lib')

# Load project lib dir
$LOAD_PATH.unshift PROJECT_DIR
$LOAD_PATH.unshift TESTS_DIR

def test_path(path)
  File.join(TESTS_DIR, path)
end

require 'helpers/start_proxy'
require 'helpers/web_server'
require 'minitest/autorun'
require 'rspec/expectations'
require 'rspec/expectations/minitest_integration'
