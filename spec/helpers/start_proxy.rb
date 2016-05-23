require 'ritm'
require 'ritm/proxy/launcher'

proxy = Ritm::Proxy::Launcher.new proxy_port: 9090,
                                  ssl_reverse_proxy_port: 9091,
                                  ca_crt_path: test_path('resources/insecure_ca.crt'),
                                  ca_key_path: test_path('resources/insecure_ca.priv')
proxy.start
Thread.pass
