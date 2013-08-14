//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Wed, Aug 07, 2013  6:22:27 PM
// Author: tomyeh
library ripple;

import "dart:async";
import "dart:io";
import "dart:collection" show HashMap, LinkedHashMap, LinkedHashSet;
import "package:meta/meta.dart";
import "package:logging/logging.dart" show Logger, Level;

import "package:stomp/stomp.dart" show Ack, AUTO, CLIENT, CLIENT_INDIVIDUAL;
import "package:stomp/impl/util.dart";
import "package:stomp/impl/plugin.dart" show StompConnector, BytesStompConnector;
import "plugin.dart";

part "src/server_impl.dart";
part "src/connect.dart";
part "src/connect_impl.dart";
part "src/connect_util.dart";

/**
 * Ripple messaging server.
 */
abstract class RippleServer {
 /** Constructor.
  *
  * * [destinationControl] - controls how to handle the subscription
  * of destionations, such as authentication.
  * If not specified, the destination will be created
  * automatically if there is a client subscribed it. It is removed
  * automatically when all clients unscribed
  */
  factory RippleServer({DestinationControl destinationControl,
    LoggingConfigurer loggingConfigurer})
  => new _RippleServer(destinationControl, loggingConfigurer);

  /** The version.
   */
  String get version;
  /** Indicates whether the server is running.
   */
  bool get isRunning;

  /** Starts the server to handle the given channel.
   *
   * Notice that you can invoke [start], [startSecure] and [startOn] multiple
   * times to handle multiple channels:
   *
   *     new RippleServer()
   *       ..start()
   *       ..startSecure()
   *       ..serveWebSocket(webSocket);
   *
   * * [address] - It can either be a [String] or an [InternetAddress].
   * Default: [InternetAddress.ANY_IP_V4] (i.e., "0.0.0.0").
   * It will cause Ripple server to listen all adapters
   * IP addresses using IPv4.
   *
   * * [port] - the port. Default: 61626.
   * If port has the value 0 an ephemeral port will be chosen by the system.
   * The actual port used can be retrieved using [RippleChannel.port].
   *
   * * [backlog] - specify the listen backlog for the underlying OS listen setup.
   * If backlog has the value of 0 (the default) a reasonable value will be chosen
   * by the system.
   */
  Future<RippleChannel> start({address, int port: 61626, int backlog: 0});
  /** Starts the server to handle the given channel with [SecureServerSocket].
   *
   * * [port] - the port. Default: 61627.
   * If port has the value 0 an ephemeral port will be chosen by the system.
   * The actual port used can be retrieved using [RippleChannel.port].
   */
  Future<RippleChannel> startSecure({address, int port: 61627,
      String certificateName, bool requestClientCertificate: false,
      int backlog: 0});
  /** Starts the server to an existing server socket.
   *
   * Unlike [start], when the channel or the server is closed, the server
   * will just detach itself, but not closing [socket].
   */
  RippleChannel startOn(ServerSocket socket);
  /** Serves the connection of an existing WebSocket.
   *
   * The [WebSocket] instance is usually retrieved from [WebSocketTransformer]
   * by transforming a HTTP request.
   */
  RippleConnect serveWebSocket(WebSocket socket);

  /** Stops the server. It will close all [channels].
   *
   * To close an individual channel, please use [RippleChannel.close] instead.
   *
   * The returned [Future] instance indicates when it is fully stopped.
   */
  Future stop();

  /** The application-specific error handler to listen all errors that
   * ever happen in this server.
   *
   * If the [connect] argument is null, it means it is a server error.
   * If not null, it means it happens when communicating with a client.
   *
   * The return value of the error handler indicates whether to report
   * the error back to the client (in the form of the ERROR frame).
   * If true or null, it will be reported to the client.
   */
  void onError(bool onError(RippleConnect connect, error, [stackTrace]));

  /** The logger for logging information.
   * The default level is `INFO`.
   */
  Logger get logger;

  /** Returns a readonly list of channels served by this server.
   * Each time [start], [startSecure] or [startOn] is called, an instance
   * is added to the returned list.
   *
   * To close a particular channel, invoke [RippleChannel.close]. To close all,
   * invoke [stop] to stop the server.
   */
  List<RippleChannel> get channels;
}
