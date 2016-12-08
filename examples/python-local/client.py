#!/usr/bin/env python

"""
Run a HTTP client that looks up the location it should connect to using the
Datawire Microservices Development Kit (MDK).

Make sure you have the DATAWIRE_TOKEN environment variable set with your
access control token.
"""

import logging
logging.basicConfig(level=logging.INFO)

import time

import mdk
# MDK integration for the Requests HTTP library:
from mdk.requests import requests_session

def main(mdk, service, version):
    while True:
        # Start a new session:
        ssn = mdk.session()

        # Wait 10 seconds for result, if no service is available an exception is
        # raised:
        url = ssn.resolve(service, version).address

        ssn.info("client", "Connecting to {}".format(url))

        # Do HTTP client request to the server, sending the MDK session
        # along. You can also do this directly using your client library of
        # choice:
        r = requests_session(ssn).get(url)
        ssn.info("client", "Got response {} (code {})".format(r.text, r.status_code))
        print("%s => %d: %s" % (url, r.status_code, r.text))

        time.sleep(1)


if __name__ == '__main__':
    import sys

    if len(sys.argv) < 2:
        raise Exception("usage: client service_name");

    service_name = sys.argv[1]

    # Only need to start MDK once per process:
    MDK = mdk.start()
    try:
        main(MDK, service_name, "1.0.0")
    finally:
        MDK.stop()
