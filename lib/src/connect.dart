//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Fri, Aug 09, 2013  1:53:34 PM
// Author: tomyeh
part of messa;

/** A channel that [StompConnect] can take place.
 * A channel can have multiple [StompConnect].
 *
 * A channel is either a [StompIPChannel] or a [SocketChannel].
 */
abstract class StompChannel {
  /** When the server started. It is null if never started.
   */
  DateTime get startedSince;
  /** Closes the channel.
   *
   * To start all channels, please use [MessaServer.stop] instead.
   */
  void close();
  /** Indicates whether the channel is closed.
   */
  bool get isClosed;

  ///The server for serving this channel.
  MessaServer get server;
}
/** A HTTP channel.
 */
abstract class StompIPChannel extends StompChannel {
  /** The address. It can be either a [String] or an [InternetAddress].
   */
  get address;
  ///The port.
  int get port;
  ///Whether it is a HTTPS channel
  bool get isSecure;
}
/** A socket channel.
 */
abstract class StompSocketChannel extends StompChannel {
  ///The socket that this channel is bound to.
  ServerSocket get socket;
}

/** A stomp connection.
 */
abstract class StompConnect {
  ///The channel that this connection belongs to.
  StompChannel get channel;
  ///The server.
  MessaServer get server;
}
