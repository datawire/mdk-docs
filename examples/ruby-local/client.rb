#!/usr/bin/env ruby

# Run a HTTP client that looks up the location it should connect to using the
# Datawire Microservices Development Kit (MDK).
#
# Make sure you have the DATAWIRE_TOKEN environment variable set with your
# access control token.

require 'rest-client'

require 'mdk'
# Only need to start MDK once per process:
$mdk = ::Quark::Mdk.start()

def main(service, version)
  while true
    # Initialize logging context:
    ssn = $mdk.session()

    # Wait 10 seconds for result, if no service is available an exception is
    # raised:
    url = ssn.resolve(service, version).address

    ssn.info("client", "Connecting to #{url}...")
    response = RestClient.get url, {$mdk.CONTEXT_HEADER => ssn.inject()}
    ssn.info("client", "Got response #{response.body} (#{response.code})")
    puts "#{url} => #{response.code}: #{response.body}"
    sleep 1
  end
end

if __FILE__ == $0
  begin
    main(ARGV[0], "1.0")
  ensure
    $mdk.stop
  end
end
