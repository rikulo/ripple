//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Mon, Aug 12, 2013 10:53:44 AM
// Author: tomyeh
part of ripple;

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
    }, onError: (error, stackTrace) {
      onError(error, stackTrace);
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
