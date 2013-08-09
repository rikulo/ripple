//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Wed, Aug 07, 2013  6:22:27 PM
// Author: tomyeh
library messa;

import "dart:async";
import "dart:io";
import "package:meta/meta.dart";
import "package:logging/logging.dart" show Logger;

import "plugin.dart";

part "src/server_impl.dart";
part "src/connect.dart";
part "src/connect_impl.dart";

/**
 * Messa messaging server.
 *
 * ##Destionations of Messages##
 *
 * In the current implementation, the destination will be created
 * automatically if there is a client subscribed it. It is removed
 * automatically when all clients unscribed
 */
abstract class MessaServer {
  factory MessaServer({DestinationControl destinationControl})
  => new _MessaServer(destinationControl);

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
   *     new MessaServer()
   *       ..start()
   *       ..startSecure()
   *       ..serveWebSocket(webSocket);
   *
   * * [address] - It can either be a [String] or an [InternetAddress].
   * Default: [InternetAddress.ANY_IP_V4] (i.e., "0.0.0.0").
   * It will cause Messa server to listen all adapters
   * IP addresses using IPv4.
   *
   * * [port] - the port. Default: 61626.
   * If port has the value 0 an ephemeral port will be chosen by the system.
   * The actual port used can be retrieved using [StompIPChannel.port].
   *
   * * [backlog] - specify the listen backlog for the underlying OS listen setup.
   * If backlog has the value of 0 (the default) a reasonable value will be chosen
   * by the system.
   */
  Future<StompIPChannel> start({address, int port: 61626, int backlog: 0});
  /** Starts the server to handle the given channel with [SecureServerSocket].
   *
   * * [port] - the port. Default: 61627.
   * If port has the value 0 an ephemeral port will be chosen by the system.
   * The actual port used can be retrieved using [StompIPChannel.port].
   */
  Future<StompIPChannel> startSecure({address, int port: 61627,
      String certificateName, bool requestClientCertificate: false,
      int backlog: 0});
  /** Starts the server to an existing server socket.
   */
  StompSocketChannel startOn(ServerSocket socket);
  /** Serves the connection of an existing WebSocket.
   *
   * The [WebSocket] instance is usually retrieved from [WebSocketTransformer]
   * by transforming a HTTP request.
   */
  StompConnect serveWebSocket(WebSocket socket);

  /** Stops the server. It will close all [channels].
   *
   * To close an individual channel, please use [StompChannel.close] instead.
   */
  void stop();
  /** The logger for logging information.
   * The default level is `INFO`.
   */
  Logger get logger;

  /** Returns a readonly list of channels served by this server.
   * Each time [start], [startSecure] or [startOn] is called, an instance
   * is added to the returned list.
   *
   * To close a particular channel, invoke [StompChannel.close]. To close all,
   * invoke [stop] to stop the server.
   */
  List<StompChannel> get channels;
}
