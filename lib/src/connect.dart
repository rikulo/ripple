//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Fri, Aug 09, 2013  1:53:34 PM
// Author: tomyeh
part of ripple;

/** A STOMP channel.
 * A channel represents the Internet address and port that [RippleServer]
 * is bound to.
 *
 * A channel can serve multiple connections ([RippleConnect]).
 * Each connection is a one-to-one network connection with a client.
 */
abstract class RippleChannel {
  /** When the server started. It is null if never started.
   */
  DateTime get startedSince;
  /** Closes the channel.
   *
   * To start all channels, please use [RippleServer.stop] instead.
   */
  Future close();
  /** Indicates whether the channel is closed.
   */
  bool get isClosed;

  ///The server for serving this channel.
  RippleServer get server;

  ///The socket that this channel is bound to.
  ServerSocket get socket;

  /** The address. It can be either a [String] or an [InternetAddress].
   * It is null if the channel is started by [RippleServer.startOn].
   */
  get address;
  ///The port.
  int get port;
  ///Whether it is a secure channel
  bool get isSecure;

  ///A list of connections that are connected to clients.
  List<RippleConnect> get connections;
}

/** A stomp connection.
 */
abstract class RippleConnect {
  ///The channel that this connection belongs to.
  RippleChannel get channel;
  ///The server.
  RippleServer get server;
  ///The socket. It is either a [Socket] or a [WebSocket].
  get socket;
}
