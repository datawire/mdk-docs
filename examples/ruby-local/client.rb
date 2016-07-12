#!/usr/bin/env ruby

# Run a HTTP client that looks up the location it should connect to using the
# Datawire Microservices Development Kit (MDK).
#
# Make sure you have the DATAWIRE_TOKEN environment variable set with your
# access control token.

require 'rest-client'

# Tell MDK's Quark layer to output logs to stdout:
require 'quark'
::DatawireQuarkCore::LoggerConfig.config.configure

require 'mdk'

def main(mdk, service, version)
  while true
    # Initialize logging context:
    ssn = mdk.session()

    # Wait 10 seconds for result, if no service is available an exception is
    # raised:
    url = ssn.resolve_until(service, version, 10.0).address

    ssn.info("client", "Connecting to #{url}...")
    response = RestClient.get url, {"X-MDK-Context" => ssn.inject()}
    ssn.info("client", "Got response #{response.body} (#{response.code})")
    puts "#{url} => #{response.code}: #{response.body}"
    sleep 1
  end
end

if __FILE__ == $0
  mdk = ::Quark::Mdk.init()
  mdk.start()
  begin
    main(mdk, ARGV[0], "1.0.0")
  ensure
    mdk.stop
  end
end
