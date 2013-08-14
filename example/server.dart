//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Fri, Aug 09, 2013 12:16:46 PM
// Author: tomyeh
library example_server;

import "package:logging/logging.dart";
import "package:ripple/ripple.dart";

/**
 * Demostration how to start a server.
 */
void main() {
  hierarchicalLoggingEnabled = true; //for debugging

  new RippleServer()
    ..logger.level = Level.FINEST //for debugging
    ..start();
}
