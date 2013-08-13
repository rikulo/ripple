//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Fri, Aug 09, 2013 12:07:19 PM
// Author: tomyeh
part of ripple;

typedef void _ConnectErrorCallback(RippleConnect connect, err, [stackTrace]);

/**
 * The implementation.
 */
class _RippleServer implements RippleServer {
  @override
  final String version = "0.5.0";
  @override
  final Logger logger;

  final DestinationControl _destinationControl;
  final List<RippleChannel> _channels = [];
  _ConnectErrorCallback _onError;

  ///<String destination, Set<subscriber>>
  final Map<String, Set<_Subscriber>> _subsOfDest = new HashMap();
  int _messageID = 0;

  _RippleServer(DestinationControl destinationControl,
    LoggingConfigurer loggingConfigurer): logger = new Logger("ripple"),
    _destinationControl = destinationControl != null ?
      destinationControl: new DestinationControl() {
    (loggingConfigurer != null ? loggingConfigurer: new LoggingConfigurer())
      .configure(logger);
  }

  @override
  void onError(void onError(RippleConnect connect, err, [stackTrace])) {
    _onError = onError;
  }
  @override
  bool get isRunning => !_channels.isEmpty;
  @override
  List<RippleChannel> get channels => _channels;

  @override
  Future<RippleChannel> start({address, int port: 61626, int backlog: 0}) {
    if (address == null)
      address = InternetAddress.ANY_IP_V4;
    return ServerSocket.bind(address, port, backlog: backlog).then((ServerSocket socket) {
      final channel = new _RippleChannel(this, socket, address, port, false);
      _startChannel(channel);
      return channel;
    });
  }
  @override
  Future<RippleChannel> startSecure({address, int port: 61627,
      String certificateName, bool requestClientCertificate: false,
      int backlog: 0}) {
    if (address == null)
      address = InternetAddress.ANY_IP_V4;
    return SecureServerSocket.bind(address, port, certificateName,
        requestClientCertificate: requestClientCertificate,
        backlog: backlog).then((SecureServerSocket socket) {
      final channel = new _RippleChannel(this, socket, address, port, true);
      _startChannel(channel);
      return channel;
    });
  }
  @override
  RippleChannel startOn(ServerSocket socket) {
    final channel = new _RippleChannel(this, socket);
    _startChannel(channel);
    return channel;
  }
  void _startChannel(RippleChannel channel) {
    final String serverInfo = "Ripple/$version";
    channel.socket.listen((Socket socket) {
      new _RippleConnect(channel, socket);
    });
    _channels.add(channel);
    _logChannel(channel);
  }
  void _logChannel(RippleChannel channel) {
    var address = channel.address;
    if (address is InternetAddress)
      address = (address as InternetAddress).address;

    logger.info("Ripple Server $version starting on "
      + (address != null ? " ${address}:${channel.port}": "${channel.socket}"));
  }

  @override
  RippleConnect serveWebSocket(WebSocket socket) {
    //TODO
  }
  @override
  void stop() {
    if (!isRunning)
      throw new StateError("Not running");
    for (final RippleChannel channel in new List.from(channels))
      channel.close();
  }
}
