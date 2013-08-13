//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Mon, Aug 12, 2013 10:53:44 AM
// Author: tomyeh
part of ripple;

/** The implementation on top of [socket].
 */
class _SocketStompConnector extends BytesStompConnector {
  final _socket;

  _SocketStompConnector(this._socket);

  @override
  void listenBytes_(void onData(List<int> bytes), void onError(error), void onDone()) {
    (_socket as Stream<List<int>>).listen(onData, onError: onError, onDone: onDone);
  }
  @override
  void writeBytes_(List<int> bytes) {
    (_socket as StreamSink<List<int>>).add(bytes);
  }
  @override
  Future writeStream_(Stream<List<int>> stream)
  => (_socket as StreamSink<List<int>>).addStream(stream);
}

///A subscriber (of a [_RippleConnect]).
class _Subscriber {
  final RippleConnect connect;
  final String id;
  final String destination;
  final Ack ack;
 
  _Subscriber(this.connect, this.id, this.destination, this.ack);
}
