//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Fri, Aug 09, 2013 12:12:22 PM
// Author: tomyeh
library ripple_plugin;

import "dart:async" show Future;
import "package:meta/meta.dart";
import "package:logging/logging.dart";
import "package:rikulo_commons/logging.dart";

import "ripple.dart" show RippleConnect;

/** The authenticator.
 */
abstract class Authenticator {
  /** Authenticates the given host, login and passcode.
   * The returned `Future` object shall carry the user object if successful,
   * such that you can decide the authorization in [AccessControl].
   * If failed, throw an instance of [AuthenticationException]:
   *
   *     Future login(RippleConnect connect, String host, String login, String passcode) {
   *       //...
   *       if (failed)
   *         throw new AuthenticationException("the cause");
   *       return new Future.value(new User(login, roles)); //any non-null object
   *     });
   *
   * If you allow the anonymous client to access some destinations, you can
   * return a special object to indicate anonymous user if [login] is null.
   * Then, you can control what he can access with [AccessControl].
   *
   * * [connect] - the connection.
   * * [host] - the host header. It is null if not specified.
   * * [login] - the login header (the user's identifier). It is null if not specified.
   * * [passcode] - the passcode header. It is null if not specified.
   */
  Future login(RippleConnect connect, String host, String login, String passcode);
  /** Logout.
   *
   * It is called when the connection is closed.
   * The user can be found in [RippleConnect.user].
   *
   *     void logout(RippleConnect connect) {
   *       //Clean up connect.user if necessary
   *     }
   */
  void logout(RippleConnect connect);
}

/** The access control.
 */
abstract class AccessControl {
  /** Test if the given destination is accessible by the given user.
   *
   * The current user can be found in [RippleConnect.user].
   * It is the value returned by [Authenticator.login].
   *
   *     bool canAccess(RippleConnect connect, String destination, String command) {
   *       final user = connect.user;
   *       ... check if user has the right to access
   *     }
   *
   * * [connect] - the connection
   * * [destination] - the destination of the messages
   * * [command] - it is either "SEND" or "SUBSCRIBE".
   *
   * * This method returns true if the access is granted; returns false
   * if not allowed (either not logged in or not allowed).
   */
  bool canAccess(RippleConnect connect, String destination, String command);
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

class _LoggingConfigurer implements LoggingConfigurer {
  @override
  void configure(Logger logger) {
    Logger.root.level = Level.INFO;
    logger.onRecord.listen(simpleLoggerHandler);
  }
}

/** The authentication being invalid.
 */
class AuthenticationException implements Exception {
  final String message;
  const AuthenticationException([this.message=""]);
  String toString() => "AuthenticationException: $message";
}
