.. include:: ../substitutions.txt

============
Architecture
============

The MDK
-------

The MDK is a language native library that is installed with a microservice.
A developer can selectively use one or all of the MDK APIs, depending on use case. The circuit breaker, deadline, and distributed session APIs of the MDK do not have any dependency on the Datawire hosted services. The service discovery and distributed tracing APIs are coupled to Datawire hosted services.

In order to support multiple languages, the MDK is implemented in `Quark <https://github.com/datawire/quark>`_. The Quark compiler transpiles the canonical MDK implementation into language native implementations. Currently, as of late 2016, Quark supports Java, Ruby, JavaScript, and Python, with Go support in progress. The use of Quark is transparent to the end developer.


The Datawire Architecture
-------------------------

The Datawire Discovery Service is a multi-tenant, cloud-based, eventually consistent data synchronization service, purpose-built for a microservices environment. The semantics of the Discovery Service are very similar to `Netflix Eureka <https://github.com/Netflix/eureka>`_. It is very suitable for applications with very high scalability requirements, where new microservices appear (or are retired) regularly, and where existing microservices instances scale up or down rapidly.

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

All of these protocol interactions are open and specified in `Quark <https://github.com/datawire/quark>`_. For example,
the Discovery protocol is `specified in Quark <https://github.com/datawire/discovery/tree/master/quark>`_.
