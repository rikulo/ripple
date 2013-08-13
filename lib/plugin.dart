//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Fri, Aug 09, 2013 12:12:22 PM
// Author: tomyeh
library ripple_plugin;

import "package:meta/meta.dart";
import "package:logging/logging.dart";
import "package:rikulo_commons/logging.dart";

/**
 * The destination control used to control the subscription
 * and creation of destinations of messages.
 */
abstract class DestinationControl {
  factory DestinationControl() => new _DestinationControl();
}

/**
 * The configurer for logging.
 */
abstract class LoggingConfigurer {
  factory LoggingConfigurer() => new _LoggingConfigurer();

  /** Configure the logger.
   */
  void configure(Logger logger);
}

class _DestinationControl implements DestinationControl {
  
}

class _LoggingConfigurer implements LoggingConfigurer {
  @override
  void configure(Logger logger) {
    Logger.root.level = Level.INFO;
    logger.onRecord.listen(simpleLoggerHandler);
  }
}
