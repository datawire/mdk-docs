=========================
Web Framework Integration
=========================

The MDK provide integration points for common web frameworks.
The number of supported frameworks will grow over time.

Hooking up the MDK will do the following:

1. Provide a catch-all error handler for your distributed system.
   If an internal server error occurs this will activate the circuit breaker.
   The circuit breaker affects any nodes resolved using MDK discovery while handling that particular request.
   Repeated errors will cause the MDK to temporarily blacklist those nodes, ensuring errors don't take down the whole system.
2. The MDK will parse the ``X-MDK-CONTEXT`` HTTP header, and either join the resulting trace session or start a new one if no header was present.
   This means logging via the MDK will be able to trace requests across multiple servers so long as the HTTP client includes the appropriate ``X-MDK-CONTEXT`` header.
3. Provide access to a corresponding MDK ``Session`` object to enable logging, discovery and other MDK functionality form within your web application.

.. contents:: Integrations
   :local:


Python
======

Django integration
------------------

To enable MDK integration you need to add the appropriate middleware to your ``settings.py``.
In Django 1.9 or earlier you add ``mdk.django.MDKSessionMiddleware`` to ``MIDDLEWARE_CLASSES``:

.. code-block:: python

   MIDDLEWARE_CLASSES = [
    ...
    'django.middleware.csrf.CsrfViewMiddleware',

    # MDK middleware:
    'mdk.django.MDKSessionMiddleware',

    'django.contrib.auth.middleware.AuthenticationMiddleware',
     ...
   ]

In Django 1.10 you add it to ``MIDDLEWARE``:

.. code-block:: python

   MIDDLEWARE = [
    ...
    'django.middleware.csrf.CsrfViewMiddleware',

    # MDK middleware:
    'mdk.django.MDKSessionMiddleware',

    'django.contrib.auth.middleware.AuthenticationMiddleware',
     ...
   ]

In order to access the MDK you can use ``request.mdk_session`` in your view.
For example:

.. code-block:: python

   from django.http import HttpResponse

   def myview(request):
       # Log a message using the MDK:
       request.mdk_session.info("djangoapp", "myview was viewed")
       return HttpResponse("hello!")


Flask integration
-----------------

To enable MDK integration with Flask simply call ``mdk.flask.mdk_setup(app)`` before ``app.run()``.
You can access the MDK session via ``flask.g.mdk_session``.

In the following example we use the MDK to resolve the address of a node and then return the result of querying the backend server at that address.
If a particular node causes errors it will end up being blacklisted and only other nodes will be resolved by the discovery client.

.. code-block:: python

   from requests import get
   from flask import g, Flask

   from mdk.flask import mdk_setup
   from mdk import MDK

   app = Flask(__name__)

   @app.route("/")
   def proxy():
       # Lookup backend server using MDK Discovery.
       node = g.mdk_session.resolve("backend_service", "1.0")

       # Pass on MDK session context via HTTP headers:
       headers = {MDK.CONTEXT_HEADER: g.mdk_session.externalize()}

       # Do HTTP request to resolved node and return the body:
       return get(node.address, headers=headers).text

   if __name__ == '__main__':
       mdk_setup(app)
       app.run()
