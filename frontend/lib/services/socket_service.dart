import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'config.dart';

class SocketService {
  late IO.Socket socket;

  void connect(String userId, Function(dynamic) onIncomingCall, Function(dynamic) onRideAccepted) {
    socket = IO.io(AppConfig.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('Socket connected');
      socket.emit('join', userId);
    });

    socket.on('incoming-call', (data) => onIncomingCall(data));
    socket.on('ride-accepted', (data) => onRideAccepted(data));

    socket.onError((e) => print('Socket error: $e'));
    socket.onDisconnect((_) => print('Socket disconnected'));
  }

  void callUser(String to, String from, String rideId) {
    socket.emit('call-user', {'to': to, 'from': from, 'rideId': rideId});
  }

  void acceptCall(String to, String rideId) {
    socket.emit('accept-call', {'to': to, 'rideId': rideId});
  }

  void rejectCall(String to) {
    socket.emit('reject-call', {'to': to});
  }

  void disconnect() {
    if (socket.connected) socket.disconnect();
  }
}

