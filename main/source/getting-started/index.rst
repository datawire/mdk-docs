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

Python::

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

We're going to use Python as our example language here; the other
languages supported by the MDK (Java, Ruby, JavaScript) are very
similar.

Let's start by initializing the MDK. In your terminal, enter your
Python environment by typing ``python``. Then, type the following:

.. code-block:: python

    import mdk
    m = mdk.init()

In a microservices environment, microservices are constantly being
created and destroyed: new versions may be rolled out, new instances
spun up or spun down based on load, and so forth. So having a robust,
real-time service registration and discovery mechanism is
essential. So let's register a service:

.. code-block:: python

    m.register("My First Service", "1.0", "http://127.0.0.1")
    m.start()

In the Mission Control dashboard, you'll see a service appear named
"My First Service" with a version of 1.0.

Finding a service
-----------------

Once you've registered a service a client can look it up and find the address of the service.

In a different terminal make sure you have the ``DATAWIRE_TOKEN`` environment variable set and then run ``python`` again.
Then, type the following:

.. code-block:: python

    import mdk
    m = mdk.init()
    m.start()
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

1. Download the Microcosm package::

    git clone https://github.com/datawire/microcosm.git

2. Install the required Python packages needed to run the Microcosm::

    cd microcosm
    pip install -r requirements.txt

3. Launch the Microcosm::

    ./microcosm run scenarios/countdown.yml

This particular scenario runs a number of microservices, with multiple instances
and versions of each.

Now log on to your account on Mission Control, and you should see each of
the microservices listed as Active and Healthy. You should also see new tracing
messages from each of the services in the Logs section.

Digging Deeper
--------------

Now that you've seen the |mdk| at a high level, it's time to dig
into the API at a deeper level to learn how to write your
own microservices using it with the :doc:`Deep Dive <../deep-dive/index>`.
