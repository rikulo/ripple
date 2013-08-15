#Ripple

Lightweight Dart messaging server; supporting [STOMP](http://stomp.github.io/) messaging protocol.

* [Home](http://rikulo.org)
* [API Reference](http://api.rikulo.org/ripple/latest)
* [Discussion](http://stackoverflow.com/questions/tagged/rikulo)
* [Git Repository](https://github.com/rikulo/ripple)
* [Issues](https://github.com/rikulo/ripple/issues)

> See also [Stomp Dart Client](https://github.com/rikulo/stomp).

[![Build Status](https://drone.io/github.com/rikulo/ripple/status.png)](https://drone.io/github.com/rikulo/ripple/latest)

##Installation

Add this to your `pubspec.yaml` (or create it):

    dependencies:
      ripple:

Then run the [Pub Package Manager](http://pub.dartlang.org/doc) (comes with the Dart SDK):

    pub install

##Usage

First, you have to import:

    import "package:ripple/ripple.dart";

Then, you can start Ripple server by binding it to any number of Internet addresses and ports.

    new RippleServer()
      ..start() //bind to port 61626
      ..startSecure(); //bind to port 61627 and using SSL

> For how to use a STOMP client to access Ripple server, please refer to [STOMP Dart Client](https://github.com/rikulo/stomp).

###WebSocket

You can have Ripple server to serve a WebSocket connection. For example,

    HttpServer httpServer;
    RippleServer rippleServer;
    ...
    httpServer.listen((request) {
      if (...) { //usually test request.uri to see if it is mapped to WebSocket
        WebSocketTransformer.upgrade(request).then((WebSocket webSocket) {
          rippleServer.serveWebSocket(webSocket);
        });
      } else {
        // Do normal HTTP request processing.
      }
    });

##Limitations

* Support STOMP 1.2 or above
* Support UTF-8 encoding

##Incompleteness

* Transaction not supported.
* Heart beat not supported.
* ACK and NACK not supported.

##Potential Enhancement

* Support subscribeBlob() better. Currently, messages will be held in the memory before sending to subscribers. It could be an issue if the message is huge.
