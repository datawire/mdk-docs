#!/usr/bin/env python

"""
Run a HTTP client that looks up the location it should connect to using the
Datawire Microservices Development Kit (MDK).

Make sure you have the DATAWIRE_TOKEN environment variable set with your
access control token.
"""

import logging
logging.basicConfig(level=logging.INFO)

import requests
import time

from mdk import init

def main(mdk, service, version):
    while True:
        # Start a new session:
        ssn = mdk.session()

        # Wait 10 seconds for result, if no service is available an exception is
        # raised:
        url = ssn.resolve_until(service, version, 10.0).address

        ssn.info("client", "Connecting to {}".format(url))
        r = requests.get(url, headers={"X-MDK-Context": ssn.inject()})
        ssn.info("client", "Got response {} (code {})".format(r.text, r.status_code))
        print("%s => %d: %s" % (url, r.status_code, r.text))

        time.sleep(1)


if __name__ == '__main__':
    import sys

    if len(sys.argv) < 2:
        raise Exception("usage: client servicename");

    service = sys.argv[1]

    MDK = init()
    MDK.start()
    try:
        main(MDK, "!!!SERV!!!", "1.0.0")
    finally:
        MDK.stop()
