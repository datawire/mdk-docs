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

    curl -# -L https://raw.githubusercontent.com/datawire/mdk/master/install.sh | bash -s -- --python

Java::

    curl -# -L https://raw.githubusercontent.com/datawire/mdk/master/install.sh | bash -s -- --java

Ruby::

    curl -# -L https://raw.githubusercontent.com/datawire/mdk/master/install.sh | bash -s -- --ruby


Javascript::

    curl -# -L https://raw.githubusercontent.com/datawire/mdk/master/install.sh | bash -s -- --javascript


Quick Start
===========

Setup
-----

We'll use Datawire Mission Control, Datawire's free cloud-based
service discovery and dashboard service, for these examples to
simplify setup.

If you haven't already created an account on Mission Control, create
an account at https://app.datawire.io. Then, click on the "Copy Token"
link on the left hand navbar and paste it into your terminal. This
will set the security token for your session.

Registering a service
---------------------

We're going to use Python as our example language here; the other
languages supported by the MDK (Java, Ruby, JavaScript) are very
similar.

Let's start by initializing the MDK. In your terminal, enter your
Python environment by typing `python`). Then, type the following:

.. code-block:: none

    import mdk
    m = mdk.init()

In a microservices environment, microservices are constantly being
created and destroyed: new versions may be rolled out, new instances
spun up or spun down based on load, and so forth. So having a robust,
real-time service registration and discovery mechanism is
essential. So let's register a service:

.. code-block:: none

    m.register("My First Service", "1.0", "http://127.0.0.1")
    m.start()

In the Mission Control dashboard, you'll see a service appear named
"My First Service" with a version of 1.0.

    
    
