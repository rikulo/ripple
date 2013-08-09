//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Fri, Aug 09, 2013 12:07:19 PM
// Author: tomyeh
part of messa;

typedef void _ConnectErrorCallback(MessaConnect connect, err, [stackTrace]);

/**
 * The implementation.
 */
class _MessaServer implements MessaServer {
  @override
  final String version = "0.5.0";
  @override
  final Logger logger;

  final DestinationControl _destinationControl;
  final List<MessaChannel> _channels = [];
  final Map<String, _Destination> _destinations = new HashMap();
  _ConnectErrorCallback _onError;

  _MessaServer(DestinationControl destinationControl,
    LoggingConfigurer loggingConfigurer): logger = new Logger("messa"),
    _destinationControl = destinationControl != null ?
      destinationControl: new DestinationControl() {
    (loggingConfigurer != null ? loggingConfigurer: new LoggingConfigurer())
      .configure(logger);
  }

  @override
  void onError(void onError(MessaConnect connect, err, [stackTrace])) {
    _onError = onError;
  }
  @override
  bool get isRunning => !_channels.isEmpty;
  @override
  List<MessaChannel> get channels => _channels;

  @override
  Future<MessaChannel> start({address, int port: 61626, int backlog: 0}) {
    if (address == null)
      address = InternetAddress.ANY_IP_V4;
    return ServerSocket.bind(address, port, backlog: backlog).then((ServerSocket socket) {
      final channel = new _MessaChannel(this, socket, address, port, false);
      _startChannel(channel);
      return channel;
    });
  }
  @override
  Future<MessaChannel> startSecure({address, int port: 61627,
      String certificateName, bool requestClientCertificate: false,
      int backlog: 0}) {
    if (address == null)
      address = InternetAddress.ANY_IP_V4;
    return SecureServerSocket.bind(address, port, certificateName,
        requestClientCertificate: requestClientCertificate,
        backlog: backlog).then((SecureServerSocket socket) {
      final channel = new _MessaChannel(this, socket, address, port, true);
      _startChannel(channel);
      return channel;
    });
  }
  @override
  MessaChannel startOn(ServerSocket socket) {
    final channel = new _MessaChannel(this, socket);
    _startChannel(channel);
    return channel;
  }
  void _startChannel(MessaChannel channel) {
    final String serverInfo = "Messa/$version";
    channel.socket.listen((Socket socket) {
      _serveSocket(channel, socket);
    });
    _channels.add(channel);
    _logChannel(channel);
  }
  void _logChannel(MessaChannel channel) {
    var address = channel.address;
    if (address is InternetAddress)
      address = (address as InternetAddress).address;

    logger.info("Messa Server $version starting on "
      + (address != null ? " ${address}:${channel.port}": "${channel.socket}"));
  }

  @override
  MessaConnect serveWebSocket(WebSocket socket) {
    //TODO
  }
  @override
  void stop() {
    if (!isRunning)
      throw new StateError("Not running");
    for (final MessaChannel channel in new List.from(channels))
      channel.close();
  }

  void _serveSocket(MessaChannel channel, socket) {
    final MessaConnect connect = new _MessaConnect(channel, socket);
    connect.asStream.listen((List<int> data) {
      print(">>receive>>${decodeUtf8(data)}");
    });
  }
}

///Info of a destination
class _Destination {

}
