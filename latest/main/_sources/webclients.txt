======================
Web Client Integration
======================

The MDK provide integration points for common HTTP client frameworks.
The number of supported frameworks will grow over time.

Hooking up the MDK will do the following:

1. Timeouts will be extracted from the MDK session and used to set the request timeout.
2. The given MDK session will be transmitted to the destination server via a ``X-MDK-CONTEXT`` HTTP header.

The session may contain sensitive information, so this functionality should only be used within servers under your own control.

.. contents:: Integrations
   :local:


Python
======

Requests
--------

To use MDK with the `Requests <https://requests.readthedocs.io>`_ library you can use the ``mdk.requests.requests_session`` API, which creates a `requests.Session <http://requests.readthedocs.io/en/master/user/advanced/#session-objects>`_ object.
For example, if you're using the MDK Flask integration:

.. code-block:: python

   from flask import g, Flask

   from mdk.flask import mdk_setup
   from mdk.requests import requests_session

   app = Flask(__name__)

   @app.route("/")
   def proxy():
       # Lookup backend server using MDK Discovery.
       node = g.mdk_session.resolve("backend_service", "1.0")

       # Use requests to do a HTTP GET that includes the MDK
       # session context and a timeout derived from the session
       # timeout:
       req_ssn = requests_session(g.mdk_session)
       return req_ssn.get(node.address).text

   if __name__ == '__main__':
       mdk_setup(app, timeout=10.0)
       app.run()

