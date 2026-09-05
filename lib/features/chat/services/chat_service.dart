import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:playhub_playbooking/core/logging/app_logger.dart';

class ChatService {
  io.Socket? _socket;
  final _messageStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _arrivalStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get onNewMessage => _messageStreamController.stream;
  Stream<Map<String, dynamic>> get onCourtArrival => _arrivalStreamController.stream;
  Stream<bool> get onConnectionState => _connectionStateController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String baseUrl, String token) {
    if (_socket != null && _socket!.connected) return;

    final wsUrl = '$baseUrl/chat';
    AppLogger.info('Connecting to WebSocket Chat Gateway at $wsUrl');

    _socket = io.io(
      wsUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1000)
          .build(),
    );

    _socket!.onConnect((_) {
      AppLogger.info('WebSocket Chat connected successfully');
      _connectionStateController.add(true);
    });

    _socket!.onDisconnect((_) {
      AppLogger.warning('WebSocket Chat disconnected');
      _connectionStateController.add(false);
    });

    _socket!.on('newMessage', (data) {
      if (data is Map) {
        _messageStreamController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('courtArrival', (data) {
      if (data is Map) {
        _arrivalStreamController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.connect();
  }

  void joinMatchRoom(String matchId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('joinMatchRoom', {'matchId': matchId});
    }
  }

  void leaveMatchRoom(String matchId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('leaveMatchRoom', {'matchId': matchId});
    }
  }

  void sendMessage(String matchId, String body, {String? clientMessageId, String messageType = 'TEXT'}) {
    if (_socket?.connected == true) {
      final payload = <String, dynamic>{
        'matchId': matchId,
        'body': body,
        'messageType': messageType,
      };
      if (clientMessageId != null) {
        payload['clientMessageId'] = clientMessageId;
      }
      _socket!.emit('sendMessage', payload);
    }
  }

  void registerCourtArrival(String matchId, {String? notes}) {
    if (_socket?.connected == true) {
      _socket!.emit('courtArrival', {
        'matchId': matchId,
        'notes': notes,
      });
    }
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _messageStreamController.close();
    _arrivalStreamController.close();
    _connectionStateController.close();
  }
}
