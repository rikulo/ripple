//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Fri, Aug 09, 2013 12:16:46 PM
// Author: tomyeh
library example_server;

import "dart:io";
import "package:logging/logging.dart";
import "package:ripple/ripple.dart";

/**
 * Demostration how to start a server serving both IP and WebSocket.
 */
void main() {
  hierarchicalLoggingEnabled = true; //for debugging

  final RippleServer rippleServer = new RippleServer()
    ..logger.level = Level.FINEST //for debugging
    ..start();

  HttpServer.bind(InternetAddress.ANY_IP_V4, 8080).then((httpServer) {
    httpServer.listen((request) {
      WebSocketTransformer.upgrade(request).then((WebSocket webSocket) {
        rippleServer.serveWebSocket(webSocket);
      });
    });
  });
}
