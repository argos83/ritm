require 'simplecov'
require 'ritm'
require 'helpers/web_server'
require 'rspec/expectations'

def test_path(path)
  File.join(File.dirname(__FILE__), path)
end

Ritm.configure do
  ssl_reverse_proxy.ca[:pem] = test_path('resources/insecure_ca.crt')
  ssl_reverse_proxy.ca[:key] = test_path('resources/insecure_ca.priv')
end

http_pid = nil
https_pid = nil

RSpec.configure do |c|
  c.before(:suite) do
    Ritm.start
    http_pid = fork { WebServer.run! }
    https_pid = fork { SslWebServer.run! }
    Thread.pass
  end
  c.after(:suite) do
    Ritm.shutdown
    Process.kill('INT', http_pid)
    Process.kill('INT', https_pid)
  end
end
