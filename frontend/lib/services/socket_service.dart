import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'config.dart';

class SocketService {
  late IO.Socket socket;

  void connect({
    required String userId,
    required Function(dynamic) onIncomingCall,
    required Function(dynamic) onRideAccepted,
    required Function(dynamic) onRideStarted,
    required Function(dynamic) onRideCompleted,
    required Function(dynamic) onRideCancelled,
    Function(dynamic)? onNewRide, // For drivers
  }) {
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
    socket.on('ride-started', (data) => onRideStarted(data));
    socket.on('ride-completed', (data) => onRideCompleted(data));
    socket.on('ride-cancelled', (data) => onRideCancelled(data));
    
    if (onNewRide != null) {
      socket.on('new-ride', (data) => onNewRide(data));
    }

    socket.onError((e) => print('Socket error: $e'));
    socket.onDisconnect((_) => print('Socket disconnected'));
  }

  void updateStatus(String userId, bool isOnline) {
    socket.emit('update-status', {'userId': userId, 'isOnline': isOnline});
  }

  void callUser(String to, String from, String callerName, String rideId) {
    socket.emit('call-user', {'to': to, 'from': from, 'callerName': callerName, 'rideId': rideId});
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

