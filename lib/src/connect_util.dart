//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Mon, Aug 12, 2013 10:53:44 AM
// Author: tomyeh
part of ripple;

/** The implementation on top of [Socket].
 */
class _SocketStompConnector extends BytesStompConnector {
  final Socket _socket;

  _SocketStompConnector(this._socket) {
    _init();
  }
  void _init() {
    _socket.listen((List<int> data) {
      if (data != null && !data.isEmpty)
        onBytes(data);
    }, onError: (error) {
      onError(error, getAttachedStackTrace(error));
    }, onDone: () {
      onClose();
    });
  }

  @override
  Future close() {
    _socket.destroy();
    return new Future.value();
  }

  @override
  void writeBytes_(List<int> bytes) {
    _socket.add(bytes);
  }
  @override
  Future writeStream_(Stream<List<int>> stream)
  => _socket.addStream(stream);
}

/** The implementation on top of [WebSocket].
 */
class _WebSocketStompConnector extends StringStompConnector {
  final WebSocket _socket; //(dart:io)

  _WebSocketStompConnector(this._socket) {
    _init();
  }
  void _init() {
    _socket.listen((data) {
      //the client might send String or bytes
      if (data is String) onString(data);
      else onBytes(data);
    }, onError: (error) {
      onError(error, getAttachedStackTrace(error));
    }, onDone: () {
      onClose();
    });
  }

  @override
  void writeString_(String string) {
    _socket.add(string);
  }
  @override
  Future close() => _socket.close();
}

///A subscriber (of a [_RippleConnect]).
class _Subscriber {
  final RippleConnect connect;
  final String id;
  final String destination;
  final Ack ack;
 
  _Subscriber(this.connect, this.id, this.destination, this.ack);
}
