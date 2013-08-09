//Copyright (C) 2013 Potix Corporation. All Rights Reserved.
//History: Fri, Aug 09, 2013 12:07:19 PM
// Author: tomyeh
part of messa;

/**
 * The implementation.
 */
class _MessaServer implements MessaServer {
  final String version = "0.8.2";

  final DestinationControl _destinationControl;

  _MessaServer(DestinationControl destinationControl)
  : _destinationControl = destinationControl != null ? destinationControl:
    new DestinationControl();
}
