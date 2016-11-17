#!/usr/bin/env python

"""
Run a HTTP server that registers its location using the Datawire
Microservices Development Kit (MDK).

Make sure you have the DATAWIRE_TOKEN environment variable set with your
access control token.
"""

import logging
logging.basicConfig(level=logging.INFO)

# Flask integration for the MDK:
from mdk.flask import mdk_setup

from flask import Flask, g
app = Flask(__name__)

@app.route("/")
def hello():
    # Log a message using the MDK session:
    g.mdk_session.info("flask-server", "Received a request.")
    return "Hello World!"


def main(service_name, host, port):
    """Run the server."""
    mdk = mdk_setup(app)
    # Register the server with Datawire Discovery service:
    mdk.register(service_name, "1.0", "http://%s:%d" % (host, port))
    try:
        app.run(host=host, port=port)
    finally:
        mdk.stop()


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
