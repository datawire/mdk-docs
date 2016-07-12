.. include:: ../substitutions.txt

=========
Deep Dive
=========

Introduction
------------

The Datawire |mdk| (MDK) offers sophisticated capabilities for quickly creating
and connecting microservices in your existing development environment. Its
API is very simple to use in both new and existing applications.

Datawire makes available a number of cloud-based services that you can
quickly leverage without having to run any extra infrastructure within your
own environment. For example, the Datawire Discovery and Tracing services are
always running in the cloud and available for your microservices developers
to use via the MDK.

Below, we'll cover the steps required to create and register a microservice
with the Datawire Discovery system, and then show how clients can then locate
the service once it's running.

Note: the code samples below are in Python, but you can see similar samples
for Java, JavaScript, and Ruby in the `MDK Examples  <https://github.com/datawire/mdk-docs/tree/master/examples>`_ repository.

Setting Up Your Environment
---------------------------

If you haven't already created an account on Mission Control, create an account
at https://app.datawire.io.
Exit the wizard, click on the "Copy Token" link on the left hand navigation bar
and then paste into your terminal.
You should see something like ``export DATAWIRE_TOKEN=<long string here>``;
this will set the security token for your session. You'll need that token set
in each terminal window that you use.

Creating a Python Microservice with the MDK
-------------------------------------------

Let's take a simple Flask-based application and convert it to a Datawire
microservice using the MDK. Here's the code for a plain Flask-based "Hello
World" microservice:

.. code-block:: python

    #!/usr/bin/env python
    import sys
    host, port = sys.argv[1:3]

    from flask import Flask, request
    app = Flask(__name__)

    @app.route("/")
    def hello():
        return "Hello World!\n"

    if __name__ == "__main__":
        app.run(host=host, port=port)

Save this file as ``microservice.py`` and run it on port 7000 using the
command:

.. code-block:: console

    python microservice.py 127.0.0.1 7000

Then, call the service using ``curl``:

.. code-block:: console

    curl http://127.0.0.1:7000

You should see the service return the string :code:`Hello World!`.

Importantly, any component that wishes to call this service also needs to
know the host and port that it's running on. Let's fix that problem using the
MDK and the Datawire Discovery Service.

The code below adds a couple of lines to import the MDK and make the service
register its endpoint address with Datawire. Replace the contents of
``microservice.py`` with it:

.. code-block:: python

    #!/usr/bin/env python

    # Add the import of mdk and atexit
    import sys, mdk, atexit
    host, port = sys.argv[1:3]

    # Build the URL which we will register with Datawire
    addr = "http://%s:%s" % (host, port)

    from flask import Flask, request
    app = Flask(__name__)

    @app.route("/")
    def hello():
        return "Hello World (via Datawire)!\n"

    if __name__ == "__main__":
        # Start the MDK and register our service information with Datawire
        m = mdk.start()
        m.register("hello", "1.0", addr)

        # Register a shutdown hook for fast de-registration from Datawire
        atexit.register(m.stop)

        app.run(host=host, port=port)

Now re-run the microservice with this command:

.. code-block:: console

    python microservice.py 127.0.0.1 7000

With just a few extra lines of code, we successfully instrumented our
original Flask-based microservice with the Datawire MDK. When we run this
application, it registers itself with the Datawire Discovery Service, and
will show up on the Datawire Mission Control UI when it's running.

Discovering the Microservice
----------------------------

Now let's see how clients will find and call our microservice using the Datawire
Discovery Service.

With your service running, launch a Python interpreter in your terminal (making
sure that the ``DATAWIRE_TOKEN`` environment variable is set correctly), and
run the following code:

.. code-block:: python

    import mdk
    m = mdk.init()
    m.start()
    print(m.session().resolve("hello", "1.0").address)
    m.stop()

It should print the value ``http://127.0.0.1:7000``. That value was returned
by the Datawire Discovery Service as the only available endpoint for the
``hello`` service.

Load Balancing across Multiple Microservices
--------------------------------------------

With the other microservice still running on port 7000, let's now run another
instance of the microservice on port 7001. Note: if you start a new terminal
window, be sure to set your ``DATAWIRE_TOKEN`` environment variable there too.

.. code-block:: console

    python microservice.py 127.0.0.1 7001

If you now look at the Datawire Mission Control web console, you'll see that
the ``hello`` microservice has 2 active 1.0 nodes listed.

Datawire's Discovery system will now load balance clients across the nodes that
are active and healthy. Launch a ``python`` interpreter and run the following
commands:

.. code-block:: python

    import mdk
    m = mdk.init()
    m.start()
    print(m.session().resolve("hello", "1.0").address)
    print(m.session().resolve("hello", "1.0").address)
    print(m.session().resolve("hello", "1.0").address)
    m.stop()

You should see the ``resolve()`` calls returning different results each time
as the Discovery system round-robins between the two available microservice
addresses (on ports 7000 and 7001).

If you kill one of your microservice instances and retry the above, you'll see
only one address get returned. Of course, if you launch even more microservices
on other ports, the Discovery system will begin to return those new addresses
too.

Microservices calling Microservices
-----------------------------------

TBD

Distributed Tracing
-------------------

Datawire's system includes a facility for distributed inter-microservice
request tracing through the collection of correlated log messages within the
Mission Control interface.

Let's take our existing ``microservice.py`` code and add two lines into
the implementation of the hello() function to log an INFO message to the
Datawire cloud:

.. code-block:: python

    #!/usr/bin/env python
    import sys, mdk, atexit
    host, port = sys.argv[1:3]
    addr = "http://%s:%s" % (host, port)

    from flask import Flask, request
    app = Flask(__name__)

    @app.route("/")
    def hello():
        # Join the logging context from the request, if possible.
        # This will collect all cross-service calls for a particular
        # request into the same group within Datawire Mission Control.
        session = m.join(request.headers.get(m.CONTEXT_HEADER))

        # Log an INFO-level trace message
        session.info("hello", "Received a request.")

        return "Hello World (via Datawire)!\n"

    if __name__ == "__main__":
        m = mdk.start()
        m.register("hello", "1.0", addr)
        atexit.register(m.stop)
        app.run(host=host, port=port)

Run this microservice on port 7000, and use ``curl http://127.0.0.1:7000`` to
call it. Then, switch over to your browser and view the Logs panel in
Datawire Mission Control. You should see a trace message group for the
current time, and if you expand it, you should see the ``Received a request``
message that was logged at INFO level.

Cross-Service Tracing
---------------------

The ability to track request flow across multiple microservices is a very
helpful feature when trying to diagnose an issue in a production environment.
Datawire's Tracing Service makes it easy to see how a request flows all
the way through a graph of microservices.

Cross-service tracing in Datawire is just an extension of the distributed
tracing model described earlier. By simply making sure that all requests
sent to another microservice include a special context header, the log
messages created as the request flow moves around the system can be tracked
and grouped together in Datawire Mission Control.

For example, if microservice A wishes to call an API on microservice B, the
code in microservice A that makes that call simply needs to add a new HTTP header to its outbound request to B, as follows:

.. code-block:: python

    # Start a new session
    ssn = mdk.session()

    # Get an active address for service B via Discovery
    url = ssn.resolve("B", "1.0").address

    # Make the request to service B with the context header added
    r = requests.get(url, headers={mdk.CONTEXT_HEADER: ssn.inject()})

Now, the outbound HTTP request to microservice B will include an extra
Datawire-specific header that identifies the request flow with a unique ID.
When any other microservices log any messages under the same ID, those messages
will be visible together in Mission Control. The code to do so within
service B is trivial:

.. code-block:: python

    @app.route("/")
    def hello():
        # Join the logging context from the request, if possible:
        ssn = MDK.join(request.headers.get(MDK.CONTEXT_HEADER))
        ssn.info(app.service_name, "Received a request.")
        return "Hello World!"

Datawire's Architecture
-----------------------

TBD
