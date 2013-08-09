//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Fri, Aug 09, 2013  1:54:04 PM
// Author: tomyeh
part of messa;

///A STOMP channel.
class _MessaChannel implements MessaChannel {
  @override
  final MessaServer server;
  @override
  final DateTime startedSince;

  bool _closed = false;

  _MessaChannel(this.server, ServerSocket socket, [this.address, int port,
      bool isSecure]): startedSince = new DateTime.now(),
      this.socket = socket,
      this.port = port != null ? port: socket.port,
      this.isSecure = isSecure != null ? isSecure: socket is SecureServerSocket;

  @override
  void close() {
    _closed = true;

    final List<MessaChannel> channels = server.channels;
    for (int i = channels.length; --i >= 0;)
      if (identical(this, channels[i])) {
        channels.removeAt(i);
        break;
      }

    //TODO: clean up connection

    if (address != null) { //not startOn
      socket.close();
    }
  }
  @override
  bool get isClosed => _closed;

  @override
  final ServerSocket socket;
  @override
  final address;
  @override
  final int port;
  @override
  final bool isSecure;
}

/** A network connection that is used to commuincate with a client.
 */
class _MessaConnect implements MessaConnect {
  @override
  final MessaChannel channel;
  @override
  final MessaServer server;
  @override
  final socket;

  _MessaConnect(MessaChannel channel, this.socket):
    this.channel = channel, server = channel.server;

  Stream<List<int>> get asStream => socket;
  StreamSink<List<int>> get asSink => socket;
}
