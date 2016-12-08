.. include:: ../substitutions.txt

===============
Getting Started
===============

Adopting microservices means that your architecture has moved from a
single entity for your business logic to many entities that talk to
each other over the network. The Datawire |mdk| gives you the APIs you
need to code and debug microservices, so that you don't need to worry
about coding basic infrastructure.

The |mdk| is designed to be very lightweight and interoperate with
your existing framework and infrastructure. The MDK supports natively
writing microservices in Ruby, Python, Java, and JavaScript today. It
is also framework agnostic: you can use Rails or Flask or NodeJS, for
example.

Installation
============

To get started with the |mdk|, install the MDK on Linux or Mac OS X.
The MDK supports multiple languages.

Python 2 and Python 3::

    pip install datawire_mdk

Ruby::

    gem install datawire_mdk

Javascript::

    npm install datawire_mdk

For Java you add ``io.datawire.mdk`` as a Maven dependency.


Quick Start
===========

Setup
-----

We'll use Datawire Mission Control, Datawire's free cloud-based
service discovery and dashboard service, for these examples to
simplify setup.

If you haven't already created an account on Mission Control, create an account at https://app.datawire.io.
Exit the wizard, click on the "Copy Token" link on the left hand navigation bar and then paste into your terminal.
You should see something like ``export DATAWIRE_TOKEN=<long string here>``; this will set the security token for your session.

Registering a service
---------------------

We're going to use Python as our example language here; the other languages supported by the MDK are very similar. Example code in `Java <https://github.com/datawire/mdk-docs/tree/master/examples/java-local>`_, `Ruby <https://github.com/datawire/mdk-docs/tree/master/examples/ruby-local>`_, `JavaScript <https://github.com/datawire/mdk-docs/tree/master/examples/javascript-local>`_, and `Python <https://github.com/datawire/mdk-docs/tree/master/examples/python-local>`_ are all available. We'll walk through a Python example in detail below.

Let's start by initializing the MDK. In your terminal, enter your
Python environment by typing ``python``. Then, type the following:

.. code-block:: python

    import mdk
    m = mdk.start()

This will start the MDK.
The MDK can be used as a singleton, so you you only need to do this once per process.

In a microservices environment, microservices are constantly being
created and destroyed: new versions may be rolled out, new instances
spun up or spun down based on load, and so forth. So having a robust,
real-time service registration and discovery mechanism is
essential. So let's register a service:

.. code-block:: python

    m.register("My First Service", "1.0", "http://127.0.0.1")

Again, you only need to do this once per process.

In the Mission Control dashboard, you'll see a service appear named
"My First Service" with a version of 1.0.

Finding a service
-----------------

Once you've registered a service a client can look it up and find the address of the service.

In a different terminal make sure you have the ``DATAWIRE_TOKEN`` environment variable set and then run ``python`` again.
Then, type the following:

.. code-block:: python

    import mdk
    m = mdk.start()
    print(m.session().resolve("My First Service", "1.0").address)
    m.stop()

You should see ``"http://127.0.0.1"`` printed - your client has found the address of the service it wants to talk to.

Because the MDK uses a smart client, the resolution logic provides a number of useful features:

* If multiple instances were registered the client would round robin between the different service addresses.
* Updates to the known providers of a service are pushed to the client as they happen.
* The client caches the known providers of a service.
  If the client can't reach the discovery service for some reason it can still use the cached values to find servers.

Running Sample Microservices
----------------------------

The `Microcosm <https://github.com/datawire/microcosm>`_ is a
Python-based simulator of multiple mock microservices that you can
quickly run within your environment in order to view them within `Datawire
Mission Control <https://app.datawire.io>`_.

To install the Microcosm, open a new terminal window, and make sure you have
the ``DATAWIRE_TOKEN`` environment variable set. You should consider using
a new `virtualenv` for this too.

1. Set the ``DATAWIRE_TOKEN`` environment variable if you haven't already. You can get the value for DATAWIRE_TOKEN from Mission Control::

     export DATAWIRE_TOKEN=<PASTE TOKEN HERE>

2. Download the Microcosm package::

    git clone https://github.com/datawire/microcosm.git

3. Install the required Python packages needed to run the Microcosm::

    cd microcosm
    pip install -r requirements.txt

4. Launch Microcosm::

    ./microcosm run scenarios/countdown.yml

5. Issue a request to the Microcosm front-end service, which will show the distributed request trace::

    curl http://localhost:5000/text

This particular scenario runs a number of microservices, with multiple instances and versions of each.

If you log in to Mission Control you should see each of the microservices listed as Active and Healthy. You should also see new tracing messages from each of the services in the Logs tab.

Understanding how the MDK works
-------------------------------

Now that you've seen some sample code, next we'll move on to a :doc:`conceptual overview <../concepts>`.
