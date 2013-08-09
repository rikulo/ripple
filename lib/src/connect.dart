//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Fri, Aug 09, 2013  1:53:34 PM
// Author: tomyeh
part of messa;

/** A STOMP channel.
 * A channel represents the Internet address and port that [MessaServer]
 * is bound to.
 *
 * A channel can serve multiple connections ([MessaConnect]).
 * Each connection is a one-to-one network connection with a client.
 *
 * A channel is either a [MessaIPChannel] or a [MessaSocketChannel].
 */
abstract class MessaChannel {
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

  ///The socket that this channel is bound to.
  ServerSocket get socket;

  /** The address. It can be either a [String] or an [InternetAddress].
   * It is null if the channel is started by [MessaServer.startOn].
   */
  get address;
  ///The port.
  int get port;
  ///Whether it is a secure channel
  bool get isSecure;
}

/** A stomp connection.
 */
abstract class MessaConnect {
  ///The channel that this connection belongs to.
  MessaChannel get channel;
  ///The server.
  MessaServer get server;
}
