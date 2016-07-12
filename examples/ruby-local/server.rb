 #!/usr/bin/env ruby

# Run a HTTP server that registers its location using Datawire Microservices
# Development Kit (MDK).
#
# Make sure you have the DATAWIRE_TOKEN environment variable set with your
# access control token.

require 'sinatra/base'

# Tell MDK's Quark layer to output logs to stdout:
require 'quark'
::DatawireQuarkCore::LoggerConfig.config.configure

require 'mdk'
$mdk = ::Quark::Mdk.init()


class MyApp < Sinatra::Application
  set :service_name, ARGV[0]
  set :port, ARGV[1]

  get '/' do
    # Join the logging context for the request, if possible:
    ssn = $mdk.join(headers['X-MDK-CONTEXT'])
    ssn.info(:service_name, "Received a request.")
    return 'Hello World!'
  end
end


def main()
  host = "127.0.0.1"  # We are reachable only on localhost
  service_name = MyApp.service_name
  port = MyApp.port

  $mdk.start()
  $mdk.register(service_name, "1.0.0", "http://#{host}:#{port}")
  begin
    MyApp.run!
  ensure
    $mdk.stop
  end
end


if __FILE__ == $0
  main()
end
