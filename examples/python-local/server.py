#!/usr/bin/env python

"""
Run a HTTP server that registers its location using the Datawire
Microservices Development Kit (MDK).

Make sure you have the DATAWIRE_TOKEN environment variable set with your
access control token.
"""

import logging
logging.basicConfig(level=logging.INFO)

from mdk import init
MDK = init()

from flask import Flask, request
app = Flask(__name__)

@app.route("/")
def hello():
    # Join the logging context from the request, if possible:
    ssn = MDK.join(request.headers.get("X-MDK-Context"))
    ssn.info(app.service_name, "Received a request.")
    return "Hello World!"


def main(service_name, host, port):
    """Run the server."""
    # Save the service name into the Flask app for later logging and such.
    app.service_name = service_name

    MDK.start()
    MDK.register(app.service_name, "1.0.0", "http://%s:%d" % (host, port))

    try:
        app.run(host=host, port=port)
    finally:
        MDK.stop()


if __name__ == "__main__":
    host = "127.0.0.1"  # We are reachable only on localhost
    port = 5000         # Default to port 5000 but allow overriding

    import sys

    if len(sys.argv) < 2:
        raise Exception("usage: client servicename");

    service_name = sys.argv[1]

    if len(sys.argv) > 2:
        port = int(sys.argv[2])

    main(service_name, host, port)
