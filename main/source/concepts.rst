.. include:: substitutions.txt

============
MDK Concepts
============

Services, service instances and versions
----------------------------------------

The MDK allows you to create a network of services that talk to each other.

A **service** is a collection of processes (known as **service instances**) that provides some functionality.
For example, you might have a Widgets service that lets you create, list and delete widgets.
If you have 4 independent processes running the Widgets service then you have 4 service instances.

Services have **versions**: as your service evolves the external API or protocol it provides will change, and the version allows you to track that.
The versioning scheme is similar to `SemVer <http://semver.org/>`_: incrementing the major versions indicates a lack of backwards compatibility, but minor version increments are backwards compatible.

In the following setup you see a Widgets 1.1 service instance, and two Widget 2.0 instances.

.. blockdiag::

   blockdiag services {
       group {
           label="Widgets";
           A [label="v1.1"];
           B [label="v2.0"];
           C [label="v2.0"];
       }
   }

* A Widget 1.0 client will be able to talk to the Widgets 1.1 instance, but not the Widgets 2.0 instance.
* A client requiring Widgets 1.2 will not be able to talk to any of the instances.


Discovery
---------

A service instance can **register** its address (e.g. its URL) with Datawire Discovery.
Clients also talk to Discovery, and get the list of registered services.
It can then use that information to **resolve** a service name and version to the address of an instance it wants to talk to:

.. blockdiag::

   blockdiag {
       group services {
           label="Widgets";
           A [label="v1.1: http://host1/"];
           B [label="v2.0: http://host2/"];
           C [label="v2.0: http://host3/"];
       }
       group clients {
           Client [label="Widgets 2.0 client"];
       }
       Disco [label="Datawire Discovery"];

       A, B, C -> Disco [style=dotted];
       Client -> C;
       Disco -> Client [style=dotted];
   }

Logging
-------

The MDK also allows service instances to **log messages** to a central server.
This functionality can be used both together and separately from tracing: you can use both or either.

Sessions
--------

A **session** allows you to keep track of information that needs to span multiple service instances.
For example, if a request comes in from an external user the session allows you to set an overall deadline for the user's request.
It also lets Datawire Mission Control combine logs from different service instances into a single trace of the external user request, since all the logs are part of the same session.


Digging Deeper
--------------

Now that you've seen the |mdk| concepts at a high level, it's time to dig
into the API at a deeper level to learn how to write your
own microservices using it with the :doc:`Deep Dive <../deep-dive/index>`.
