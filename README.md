#Messa

Lightweight Dart messaging server; supporting [STOMP](http://stomp.github.io/) messaging protocol.

* [Home](http://rikulo.org)
* [API Reference](http://api.rikulo.org/messa/latest)
* [Discussion](http://stackoverflow.com/questions/tagged/rikulo)
* [Git Repository](https://github.com/rikulo/messa)
* [Issues](https://github.com/rikulo/messa/issues)

> See also [Stomp Dart Client](https://github.com/rikulo/stomp).

##Installation

Add this to your `pubspec.yaml` (or create it):

    dependencies:
      messa:

Then run the [Pub Package Manager](http://pub.dartlang.org/doc) (comes with the Dart SDK):

    pub install

##Usage

First, you have to import:

    import "package:messa/messa.dart";

Then, you can start Messa server by binding it to any number of Internet addresses and ports.

    new MesaServer()
      ..start() //bind to port 61626
      ..startSecure(); //bind to port 61627 and using SSL

###WebSocket

You can have Messa server to serve a WebSocket connection. For example,

    HttpServer httpServer;
    MessaServer messaServer;
    ...
    httpServer.listen((request) {
      if (...) { //usually test request.uri to see if it is mapped to WebSocket
        WebSocketTransformer.upgrade(request).then((WebSocket webSocket) {
          messaServer.serveWebSocket(webSocket);
        });
      } else {
        // Do normal HTTP request processing.
      }
    });

##Limitations

* Support STOMP 1.2 or above
* Support UTF-8 encoding
* No transaction support
