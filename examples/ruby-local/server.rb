#!/usr/bin/env ruby

# Run a HTTP server that registers its location using Datawire Microservices
# Development Kit (MDK).
#
# Make sure you have the DATAWIRE_TOKEN environment variable set with your
# access control token.

require 'sinatra/base'

# MDK only needs to be started once per process:
require 'mdk'
$mdk = ::Quark::Mdk.start()
SERVICE_NAME = ARGV[0]

class MyApp < Sinatra::Application
  set :port, ARGV[1]

  get '/' do
    # Join the logging context for the request, if possible:
    ssn = $mdk.join(headers[$mdk.CONTEXT_HEADER])
    ssn.info(SERVICE_NAME, "Received a request.")
    return 'Hello World!'
  end
end


def main()
  host = "127.0.0.1"  # We are reachable only on localhost
  port = MyApp.port

  $mdk.register(SERVICE_NAME, "1.0.0", "http://#{host}:#{port}")
  begin
    MyApp.run!
  ensure
    $mdk.stop
  end
end


if __FILE__ == $0
  main()
end
