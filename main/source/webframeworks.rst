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
4. If appropriately configured, propagate a session timeout with the session context, allowing different servers to cooperate in enforcing a global timeout.

.. contents:: Integrations
   :local:

Javascript
==========

Express integration
-------------------

Express support requires adding an additional dependency::

  npm install datawire_mdk_express

You will then need to:

* Add a ``mdkSessionStart`` middleware at the beginning of your application configuration.
  This will ensure the MDK session is started and stopped appropriately.
* Add a ``mdkErrorHandler`` error-handling middleware at the end of your application configuration.
  This catches errors passed into Express and ensures the circuit breaker will be called in that case.

Unfortunately not all errors end up being passed back to Express.
For example, if an exception is thrown in a callback somewhere Express will have no way of knowing about it.

To ensure that these cases also trigger the circuit breaker, and that some sort of response is sent even when unhandled errors occur, we highly recommend you add a timeout middleware.
The ``connect-timeout`` package (https://www.npmjs.com/package/connect-timeout) works well for this since it can be configured to trigger an Express error when the timeout occurs.

Once you've configured the MDK as above you can access the session via ``req.mdk_session``.
Here's an example showing the full configuration:

.. code-block:: javascript

   var express = require('express');
   var timeout = require('connect-timeout');
   var mdk_express = require('datawire_mdk_express');

   // Configure a 5 second global timeout on MDK sessions passing through this
   // process:
   mdk_express.mdk.setDefaultTimeout(5.0);
   // Register the server with Discovery:
   mdk_express.mdk.register("myservice", "1.0", "http://localhost:8080/")

   var app = express();

   // Configure a 5 second timeout which will cause an Express error on
   // timeouts within this process:
   app.use(timeout('5s', {respond: true}));

   // Start and stop the MDK session:
   app.use(mdk_express.mdkSessionStart);


   // Your application logic goes here:
   app.get('/', function (req, res) {
       // Log a message using the MDK:
       req.mdk_session.info("myapp", "logging some info");
       res.send("hello world");
   });
   // ... more application logic ...


   // Error handler which has to go at the end of your middleware:
   app.use(mdk_express.mdkErrorHandler);


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

You will also need to add either ``mdk.django.MDKAppConfig`` or a subclass to ``INSTALLED_APPS`` in your ``settings.py``.
Subclassing and overriding the ``MDKAppConfig.mdk_ready`` method will allow you to run MDK setup on startup, e.g. registering your server with discovery or setting a default timeout.

.. code-block:: python

   from mdk.django import MDKAppConfig

   class LocalMDKAppConfig(MDKAppConfig):
       def mdk_ready(self, mdk):
           mdk.register("myapp", "1.0", "https://example.com")
           mdk.setDefaultTimeout(5.0)

   INSTALLED_APPS = [
       'LocalMDKAppConfig',
       # ... default Django apps
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
This will return the ``MDK`` instance.
You can access an automatically setup MDK session via ``flask.g.mdk_session``.

.. code-block:: python

   from requests import get
   from flask import g, Flask

   from mdk.flask import mdk_setup

   app = Flask(__name__)

   @app.route("/")
   def hello():
       g.mdk_session.info("myservice", "Hello world!")
       return "hello"

   if __name__ == '__main__':
       mdk = mdk_setup(app)
       mdk.setDefaultTimeout(10.0)
       mdk.register("helloservice", "1.0", "http://localhost:7070/")
       app.run(port=7070)


Ruby
====

Rack
----

Rack is the basis for many Ruby web frameworks, including Sinatra and Ruby on Rails.
The MDK Rack middleware therefore allows integrating the MDK into all these web frameworks.

You will need to install the ``rack-mdk`` gem, e.g.::

  gem install rack-mdk

Then register the ``Rack::MDK::Session`` middleware with your Rack configuration.
You can access the current session from the Rack ``env`` via ``env[:mdk_session]``.

For example, here's how you would do so in Sinatra:

.. code-block:: ruby

   require 'sinatra'
   require 'rack-mdk'

   # Register the MDK middleware using the Sinatra use API
   use Rack::MDK::Session do |mdk|
     mdk.setDefaultTimeout(10)
     mdk.register("myservice", "1.0", "http://localhost:8080")
   end

   get '/' do
     # Log using the MDK
     env[:mdk_session].info('myapp', 'Logging something')
     'hello!'
   end
