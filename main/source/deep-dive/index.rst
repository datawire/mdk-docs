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

Distributed Logging
-------------------

TBD

Multiple Microservices
----------------------

TBD

Datawire's Discovery Architecture
---------------------------------

TBD
