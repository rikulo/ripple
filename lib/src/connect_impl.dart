//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Fri, Aug 09, 2013  1:54:04 PM
// Author: tomyeh
part of ripple;

///A STOMP channel.
class _RippleChannel implements RippleChannel {
  @override
  final _RippleServer server;
  @override
  final DateTime startedSince;

  @override
  bool get isWebSocket => socket == null;

  bool _closed = false;

  _RippleChannel(this.server, ServerSocket socket, [this.address, int port,
      bool isSecure]): startedSince = new DateTime.now(),
      this.socket = socket,
      this.port = port != null ? port: socket.port,
      this.isSecure = isSecure != null ? isSecure: socket is SecureServerSocket;

  _RippleChannel.webSocket(this.server): startedSince = new DateTime.now(),
      socket = null, address = null, port = 0, isSecure = false;

  @override
  Future close() {
    _closed = true;

    final List<RippleChannel> channels = server.channels;
    for (int i = channels.length; --i >= 0;)
      if (identical(this, channels[i])) {
        channels.removeAt(i);
        break;
      }

    for (final _RippleConnect connect in new List.from(connections))
      connect._connector.close();

    return address != null ? socket.close(): new Future.value();
      //don't close startOn and serveWebSocket
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
  @override
  final List<_RippleConnect> connections = [];
}

/** A network connection that is used to commuincate with a client.
 */
class _RippleConnect implements RippleConnect {
  FrameParser _parser;
  StompConnector _connector;
  ///<String id, subscriber>
  final Map<String, _Subscriber> _subscribers = new HashMap();
  var _user;

  @override
  final RippleChannel channel;
  @override
  _RippleServer get server => channel.server;
  @override
  final socket;
  @override
  get user => _user;

  _RippleConnect(RippleChannel channel, this.socket):
      this.channel = channel {
    channel.connections.add(this);
    _connector = socket is WebSocket ? new _WebSocketStompConnector(socket):
        new SocketStompConnector(socket);
    _init();
  }
  void _init() {
    if (server.logger.isLoggable(Level.FINEST))
      server.logger.finest("Connection ${_connector.hashCode} "
        + (socket is WebSocket ? "(WebSocket) ": "")
        + "established (total ${channel.connections.length})");

    _parser = new FrameParser((Frame frame) {
      if (server.logger.isLoggable(Level.FINEST))
        server.logger.finest("Receive: ${frame.command}/${frame.headers}/${frame.message}");

      final _FrameHandler handler = _frameHandlers[frame.command];
      if (handler != null)
        handler(this, frame);
      else
        _replyError("unknown command", "Unknown command: ${frame.command}");
    }, (error, stackTrace) {
      _handleErr(error, stackTrace);
    });
    _connector
      ..onBytes = (List<int> data) {
        _parser.addBytes(data);
      }
      ..onString = (String string) {
        _parser.addString(string);
      }
      ..onError = (error, stackTrace) {
        _handleErr(error, stackTrace);
      }
      ..onClose = () {
        if (server.logger.isLoggable(Level.FINE))
          server.logger.fine("Disconnected ${_connector.hashCode}");

        channel.connections.remove(this);
        server._channels.remove(channel);
        for (final _Subscriber sub in _subscribers.values)
          _unsubscribe0(sub);
        _subscribers.clear();

        if (server.authenticator != null)
          server.authenticator.logout(this);
      };
  }
  void _replyError(String message, String detail,
      {String subscription, String destination, String messageID}) {
    final Map<String, String> headers = new LinkedHashMap();
    headers["message"] = message;
    if (subscription != null)
      headers["subscription"] = subscription;
    if (destination != null)
      headers["destination"] = destination;
    if (messageID != null)
      headers["messageID"] = messageID;
    writeDataFrame(_connector, ERROR, headers, detail);
  }
  void _handleErr(error, [stackTrace]) {
    if (server._handleErr(this, error, stackTrace))
      _replyError("$error", stackTrace != null ? "$error\n$stackTrace": null);
  }
  void _replyReceipt(Map<String, String> headers) {
    if (headers != null) {
      final String receipt = headers["receipt"];
      if (receipt != null) {
        writeSimpleFrame(_connector, RECEIPT, {"receipt-id": receipt});
      }
    }
  }

  bool _canAccess(String destination, String command) {
    if (server.accessControl != null
    && !server.accessControl.canAccess(this, destination, command)) {
      _replyError("Access denied", "You have no right to $command $destination");
      return false;
    }
    return true;
  }

  //Frame Handlers//
  void _connect(Frame frame) {
    if (server.logger.isLoggable(Level.FINE))
      server.logger.fine("Connected ${_connector.hashCode}");

    //TODO: check accept-version and heart-beat
    Map<String, String> headers = frame.headers;

    if (server.authenticator == null) {
      _connect0();
      return;
    }

    if (headers == null)
      headers = const {};
    server.authenticator
    .login(this, headers["host"], headers["login"], headers["passcode"])
    .then((user) {
      this._user = user;
      _connect0();
    })
    .catchError((ex) {
      if (ex is AuthenticationException)
        _replyError("Authentication failed", ex.message);
      else
        _handleErr(ex, getAttachedStackTrace(ex));
      _disconnect0();
    });
  }
  void _connect0() {
    final Map<String, String> headers = {
      "version": "1.2",
      "server": "Ripple/${server.version}",
      "session": "${_connector.hashCode}"
    };
    writeSimpleFrame(_connector, CONNECTED, headers);
  }

  void _disconnect(Frame frame) {
    _replyReceipt(frame.headers);
    _disconnect0();
  }
  void _disconnect0() {
    //wait a moment, so the client has the chance to receive the receipt
    new Future.delayed(const Duration(milliseconds: 50), () {
      _connector.close();
    });
  }

  void _subscribe(Frame frame) {
    final Map<String, String> headers = frame.headers;
    String id, destination;
    if (headers != null) {
      id = headers["id"];
      destination = headers["destination"];
      if (id != null && destination != null) {
        if (server.logger.isLoggable(Level.FINE))
          server.logger.fine("Subscribe: $id, $destination");

        if (_subscribers[id] != null) {
          _replyError("subscribe failed", "Subscription $id can't be subscribed twice",
            subscription: id, destination: destination);
          return;
        }

        if (!_canAccess(destination, SUBSCRIBE))
          return;

        final _Subscriber sub = _subscribers[id]
          = new _Subscriber(this, id, destination, _getAck(headers));

        final Map<String, Set<_Subscriber>> subsOfDest = server._subsOfDest;
        Set<_Subscriber> subs = subsOfDest[destination];
        if (subs == null)
          subs = subsOfDest[destination] = new LinkedHashSet();
        subs.add(sub);

        _replyReceipt(frame.headers);
        return;
      }
    }
    _replyError("subscribe failed", "Both id and destination are required",
      subscription: id, destination: destination);
  }
  void _unsubscribe(Frame frame) {
    final Map<String, String> headers = frame.headers;
    if (headers != null) {
      final String id = headers["id"];
      if (id != null) {
        final _Subscriber sub = _subscribers.remove(id);
        if (sub != null)
          _unsubscribe0(sub);

        _replyReceipt(frame.headers);
        return;
      }
    }
    _replyError("unsubscribe failed", "id is required");
  }
  void _unsubscribe0(_Subscriber sub) {
    if (server.logger.isLoggable(Level.FINE))
      server.logger.fine("Unsubscribe: ${sub.id}, ${sub.destination}");

    final String destination = sub.destination;
    final Set<_Subscriber> subs = server._subsOfDest[destination];
    subs.remove(sub);
    if (subs.isEmpty)
      server._subsOfDest.remove(destination);
  }

  void _send(Frame frame) {
    final Map<String, String> headers = frame.headers;
    String destination;
    if (headers != null) {
      String destination = headers["destination"];
      if (destination != null) {
        if (!_canAccess(destination, SEND))
          return;

        //TODO: handle transaction
        final Set<_Subscriber> subs = server._subsOfDest[destination];
        if (subs != null) {
          headers["message-id"] = server._messageID.toString();

          for (final _Subscriber sub in subs) {
            //TODO: handle ACK
            headers["subscription"] = sub.id;
            writeDataFrame(_connector, MESSAGE, headers, frame.string, frame.bytes);
          }
          server._messageID = (server._messageID + 1) & 0x3fffffff;
        }

        _replyReceipt(frame.headers);
        return;
      }
    }
    _replyError("send failed", "destination is required", destination: destination);
  }
}

typedef void _FrameHandler(_RippleConnect connect, Frame frame);
final Map<String, _FrameHandler> _frameHandlers = {
  CONNECT: _connect,
  STOMP: _connect,
  DISCONNECT: (_RippleConnect connect, Frame frame) {
    connect._disconnect(frame);
  },

  SUBSCRIBE: (_RippleConnect connect, Frame frame) {
    connect._subscribe(frame);
  },
  UNSUBSCRIBE: (_RippleConnect connect, Frame frame) {
    connect._unsubscribe(frame);
  },

  SEND: (_RippleConnect connect, Frame frame) {
    connect._send(frame);
  }
};

void _connect(_RippleConnect connect, Frame frame) {
  connect._connect(frame);
}

Ack _getAck(Map<String, String> headers) {
  if (headers != null) {
    final String val = headers["ack"];
    if (val != null)
      switch (val) {
        case "client": return CLIENT;
        case "client-individual": return CLIENT_INDIVIDUAL;
      }
  }
  return AUTO;
}
