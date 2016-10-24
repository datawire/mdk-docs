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

Creating a Microservice with the MDK
------------------------------------

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

Service Discovery
-----------------

Now let's see how clients will find and call our microservice using the Datawire
Discovery Service.

With your service running, launch a Python interpreter in your terminal (making
sure that the ``DATAWIRE_TOKEN`` environment variable is set correctly), and
run the following code:

.. code-block:: python

    import mdk
    m = mdk.start()
    print(m.session().resolve("hello", "1.0").address)
    m.stop()

It should print the value ``http://127.0.0.1:7000``. That value was returned
by the Datawire Discovery Service as the only available endpoint for the
``hello`` service.

Load Balancing
--------------

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
    m = mdk.start()
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

Microservices normally call other microservices. Doing so with the Datawire MDK
and the associated Service Discovery system can be used to avoid having to
deploy expensive per-service load balancers, cumbersome sidecar proxies, or
other conventional pieces of software infrastructure.

The code below illustrates how to resiliently call another microservice
that is first located using the Service Discovery API in the MDK. It loops
every second, resolving a new address each time. The resolution is extremely
fast (and completely local) since the MDK synchronizes the service routing table
with the Discovery service in the cloud, and it maintains a local copy of the
always up-to-date service table in-process.

.. code-block:: python

    #!/usr/bin/env python
    import requests, time, mdk

    def main(mdk, service, version):
        while True:
            # Start a new session
            ssn = mdk.session()

            # Resolve the service name to a real endpoint address
            url = ssn.resolve(service, version).address

            # Make the request, passing in our request tracing header
            r = requests.get(url, headers={mdk.CONTEXT_HEADER: ssn.inject()})
            print("%s => %d: %s" % (url, r.status_code, r.text))

            # Wait before we resolve a new address and call again
            time.sleep(1)

    if __name__ == '__main__':
        import sys
        if len(sys.argv) < 2:
            raise Exception("usage: client service_name");

        service_name = sys.argv[1]
        MDK = mdk.start()
        try:
            main(MDK, service_name, "1.0.0")
        finally:
            MDK.stop()

First, save the above code as ``client.py``. Then, run at least a couple of
``hello`` microservices locally. Finally, run the code above with the command:

.. code-block:: console

    python client.py hello

You should see a new address chosen each second as the load balancing logic
in the MDK round-robins through the set of available service instance URLs.

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
    r = requests.get(url, headers={mdk.CONTEXT_HEADER: ssn.externalize()})

Now, the outbound HTTP request to microservice B will include an extra
Datawire-specific header that identifies the request flow with a unique ID.
When any other microservices log any messages under the same ID, those messages
will be visible together in Mission Control. The code to do so within
service B is trivial:

.. code-block:: python

    @app.route("/")
    def hello():
        # Join the logging context from the request, if possible:
        ssn = mdk.join(request.headers.get(mdk.CONTEXT_HEADER))
        ssn.info(app.service_name, "Received a request.")
        return "Hello World!"




Circuit Breakers
----------------

Circuit breakers are powerful abstractions that help limit the scope of failure. The MDK includes native support for circuit breakers that are integrated with service discovery. For example, imagine service A calls service B, and service B returns a result that triggers an exception in A. A can blacklist service B for a certain period of time, and fall back to an older version of B, periodically testing to see if the new version of B returns the proper result. Here is an example of a circuit breaker:

.. code-block:: python

    ssn.start_interaction()
    node = ssn.resolve(service, version)
    try:
         response = requests.get(node.address, headers={m.CONTEXT_HEADER: ssn.inject()}, timeout=3.0)
         ssn.info(config.name, "%s initiating request to %s" % (config.node, node))
         responder_data = response.json()
         ssn.info(config.name, "%s got response %s" % (config.node, responder_data['request_id']))
         result['requests'].append(responder_data)
         ssn.finish_interaction()
    except:
         ssn.fail_interaction("%s, %s: %s" % (config.service, config.node, traceback.format_exc()))
         result['requests'].append("ERROR(%s)" % node)

There are three methods used to wrap a remote call with a circuit breaker. To start a circuit breaker, use the ``start_interaction`` method. This method starts the interaction with a remote service, and tracks the different services that are invoked during the interaction. This could be a single service, or multiple services. When the interaction has successfully completed, the ``finish_interaction`` method is called, which will record the interaction as successfully completing. If an interaction fails, the ``fail_interaction`` method is called, which will record a failed interaction. With a failed interaction, the services that are invoked are blacklisted.  By default, three failures will trigger the circuit breaker to blacklist the services for 30 seconds.

Distributed Timeouts
--------------------

In order to build a robust distributed system you need not only circuit breakers in case of errors, but also timeouts in case a request never returns a response.
The MDK allows you to attach a deadline to an MDK session, and that deadline will be tracked across all the processes that use that particular session.
At any time you can query the session for the remaining time and use that as a parameter to APIs that take a timeout argument.

For example:

.. code-block:: python

   # Do a HTTP request with timeout based on the MDK session deadline:
   requests.get(url, timeout=ssn.getRemainingTime())

Servers should always set a default deadline which will be applied to both incoming and newly created sessions.
If the incoming session already has a deadline set then the lower of the two deadlines will be used.

.. code-block:: python

   mdk.setDefaultDeadline(10.0)

You can also set a per-session deadline.
Again, if a deadline was already set the lower of the two will be used.

.. code-block:: python

   mdk.setDeadline(5.0)


Custom Properties on Distributed Sessions
------------------------------------------

Besides deadlines you can also set arbitrary properties on a distributed session.
Process P1 can set a property on the session and then sends it to process P2.
Notice the use of a prefix ``"demoapp"`` added to the ``"items"`` key; this ensures the property doesn't conflict with built-in properties or properties from other applications.

.. code-block:: python

   # Create a session:
   session = mdk.session()
   # Set a property; any JSON-encodable value can be used:
   session.setProperty("demoapp:items", [1, 2])

   # Serialize the session for transmission to another process:
   return session.externalize()

Process P2 can then check and retrieve properties:

.. code-block:: python

   session = mdk.join(encoded_session)
   session.hasProperty("demoapp:items")  # returns True
   session.getProperty("demoapp:items")  # returns [1, 2]


Derived Sessions
----------------

The distributed session and tracing mechanism described in previous sections is intended for RPC or other remote API calls.
In particular the result of ``Session.externalize()`` should only be used once.
In other cases you might want to track the relationship between operations that result from 1->N broadcasts.
For example, you might publish a message to a pub/sub system where multiple subscribers receive a message.

For these cases the MDK provides "derived" sessions.
Instead of calling ``mdk.join(encoded_session)`` use ``mdk.derive(encoded_session)`` instead.

A derived session is a new session, but when it created it logs its relationship with the parent session.
It also inherits almost all properties from the original session.
The only property that isn't inherited is the deadline, because asynchronous systems like pub/sub can take an arbitrary amount of time before the subscriber gets messages.

The Datawire Architecture
-------------------------

The Datawire Discovery Service is a multi-tenant, cloud-based, eventually
consistent data synchronization service, purpose-built for a microservices
environment. It is very suitable for applications with very high scalability
requirements, where new microservices appear (or are retired) regularly, and
where existing microservices instances scale up or down rapidly.

As microservices instrumented with the MDK are launched, they register
themselves with the Discovery Service in the cloud over a Web Socket connection.
The registration data includes the service name, the address (typically a URL)
of that instance's endpoint, and the version of that service. At that point,
an efficient background heartbeat sequence begins over the Web Socket
connection, with the service instance regularly informing the Discovery Service
that it's still alive and should not be removed from the service routing table
that it maintains.

If the service should terminate unexpectedly or become unresponsive, the
Discovery service will quickly notice the lack of heartbeats and remove the
service instance from its list of active endpoints. If the service terminates
gracefully, it asks to be removed from the list of active endpoints immediately
as part of the ``stop()`` function.

On the client side, a Web Socket connection is also opened to the Discovery
Service when the ``start()`` function is called. The MDK on the client side
immediately receives a copy of the service routing table, and any changes
to the service endpoint listings are instantly and automatically sent
over the same Web Socket connection. This ensures that MDK clients will
always have a local, in-process copy of the potential service instances
which they could call.

Should any component in the system temporarily lose contact with the Datawire
Discovery Service, they will retain the last known copy of the service routing
table, and will have it updated again once they reconnect.

All of these protocol interactions are completely open, thanks to their being
specified in `Quark <https://github.com/datawire/quark>`_, a dedicated language
that Datawire created to precisely specify protocol interactions. For example,
the Discovery protocol is `specified in Quark <https://github.com/datawire/discovery/tree/master/quark>`_ and then compiled
into the currently supported target languages (Python, Java, JavaScript, and
Ruby). Broader language support is planned for the near future.
