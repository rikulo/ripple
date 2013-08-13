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

  bool _closed = false;

  _RippleChannel(this.server, ServerSocket socket, [this.address, int port,
      bool isSecure]): startedSince = new DateTime.now(),
      this.socket = socket,
      this.port = port != null ? port: socket.port,
      this.isSecure = isSecure != null ? isSecure: socket is SecureServerSocket;

  @override
  void close() {
    _closed = true;

    final List<RippleChannel> channels = server.channels;
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

  @override
  final RippleChannel channel;
  @override
  _RippleServer get server => channel.server;
  @override
  final socket;

  _RippleConnect(RippleChannel channel, this.socket):
      this.channel = channel {
    channel.connections.add(this);
    _connector = new _SocketStompConnector(socket);
    _init();
  }
  void _init() {
    _parser = new FrameParser((Frame frame) {
print(">>from client:${frame.command}:${frame.headers}:${frame.message}");
      final _FrameHandler handler = _frameHandlers[frame.command];
      if (handler != null)
        handler(this, frame);
      else
        _replyError("Unknown command: ${frame.command}");
    }, (error, stackTrace) {
      _handleErr(error, stackTrace);
    });
    _connector
      ..onBytes = (List<int> data) {
        _parser.addBytes(data);
      }
      ..onError = (error, stackTrace) {
        _handleErr(error, stackTrace);
      }
      ..onClose = () {
        //TODO
      };
  }
  void _replyError(String message) {
    writeDataFrame(_connector, ERROR, null, message);
  }
  void _handleErr(error, [stackTrace]) {
    if (stackTrace != null)
      server.logger.shout("$error\n$stackTrace");
    _replyError("$error");
  }

  //Frame Handlers//
  void _connect(Frame frame) {
    //TODO: check accept-version, host, login, passcode and heart-beat
    //TODO: generate session
    final Map<String, String> headers = {
      "version": "1.2",
      "server": "Ripple/${server.version}"
    };
    writeSimpleFrame(_connector, CONNECTED, headers);
  }

  void _subscribe(Frame frame) {
    final Map<String, String> headers = frame.headers;
    if (headers != null) {
      final String id = headers["id"],
        destination = headers["destination"];
      if (id != null && destination != null) {
        if (_subscribers[id] != null) {
          _replyError("Subscription $id can't be subscribed twice");
          return;
        }

        final _Subscriber sub = _subscribers[id]
          = new _Subscriber(this, id, destination, _getAck(headers));

        final Map<String, Set<_Subscriber>> subsOfDest = server._subsOfDest;
        Set<_Subscriber> subs = subsOfDest[destination];
        if (subs == null)
          subs = subsOfDest[destination] = new LinkedHashSet();
        subs.add(sub);
        return;
      }
    }
    _replyError("Both id and destination are required");
  }
  void _unsubscribe(Frame frame) {
    final Map<String, String> headers = frame.headers;
    if (headers != null) {
      final String id = headers["id"];
      if (id != null) {
        final _Subscriber sub = _subscribers.remove(id);
        if (sub != null) {
          final String destination = sub.destination;
          final Set<_Subscriber> subs = server._subsOfDest[destination];
          subs.remove(sub);
          if (subs.isEmpty)
            server._subsOfDest.remove(destination);
        }
        return;
      }
    }
    _replyError("id is required");
  }

  void _send(Frame frame) {
    final Map<String, String> headers = frame.headers;
    if (headers != null) {
      final String destination = headers["destination"];
      if (destination != null) {
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
        return;
      }
    }
    _replyError("destination is required");
  }
}

typedef void _FrameHandler(_RippleConnect connect, Frame frame);
final Map<String, _FrameHandler> _frameHandlers = {
  "CONNECT": _connect,
  "STOMP": _connect,

  "SUBSCRIBE": (_RippleConnect connect, Frame frame) {
    connect._subscribe(frame);
  },
  "UNSUBSCRIBE": (_RippleConnect connect, Frame frame) {
    connect._unsubscribe(frame);
  },

  "SEND": (_RippleConnect connect, Frame frame) {
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
