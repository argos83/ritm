require 'simplecov'
require 'ritm'
require 'helpers/web_server'
require 'rspec/expectations'

def test_path(path)
  File.join(File.dirname(__FILE__), path)
end

proxy = Ritm::Proxy::Launcher.new ca_crt_path: test_path('resources/insecure_ca.crt'),
                                  ca_key_path: test_path('resources/insecure_ca.priv')
http_pid = nil
https_pid = nil

RSpec.configure do |c|
  c.before(:suite) do
    proxy.start
    http_pid = fork { WebServer.run! }
    https_pid = fork { SslWebServer.run! }
    Thread.pass
  end
  c.after(:suite) do
    proxy.shutdown
    Process.kill('INT', http_pid)
    Process.kill('INT', https_pid)
  end
end
