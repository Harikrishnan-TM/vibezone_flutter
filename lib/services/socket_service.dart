import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

typedef CallCallback = void Function();
typedef RefreshCallback = void Function(List<dynamic>);
typedef CallEndedCallback = void Function();

class SocketService {
  static final SocketService _instance = SocketService._internal();

  WebSocketChannel? _channel;
  CallCallback? _onIncomingCall;
  RefreshCallback? _onRefreshUsers;
  CallEndedCallback? _onCallEnded;

  bool _isListening = false;

  SocketService._internal();

  factory SocketService.getInstance() => _instance;

  void registerCallbacks({
    required CallCallback onIncomingCall,
    required RefreshCallback onRefreshUsers,
  }) {
    _onIncomingCall = onIncomingCall;
    _onRefreshUsers = onRefreshUsers;
  }

  void connect() {
    if (_channel != null && _channel!.closeCode == null) {
      print('[🔌] WebSocket already connected.');
      return;
    }

    try {
      final wsUrl = dotenv.env['SOCKET_URL'] ?? 'ws://localhost:8000/ws/online-users/';
      final uri = Uri.parse(wsUrl);

      print('[🌐] Connecting to WebSocket: $uri');
      _channel = WebSocketChannel.connect(uri);

      if (!_isListening) {
        _listen();
        _isListening = true;
      }
    } catch (e) {
      print('[❌] Failed to connect to WebSocket: $e');
    }
  }

  void _listen() {
    _channel?.stream.listen(
      (event) {
        try {
          final data = json.decode(event);

          switch (data['type']) {
            case 'call':
              print('[📞] Incoming call event received.');
              _onIncomingCall?.call();
              break;

            case 'refresh_users':
              print('[🔄] Refresh users event received.');
              List<dynamic> newUsers = data['payload']['users'];
              _onRefreshUsers?.call(newUsers);
              break;

            case 'callEnded':
              print('[📴] Call ended event received.');
              _onCallEnded?.call();
              break;

            default:
              print('[⚠️] Unknown WebSocket event: $data');
          }
        } catch (e) {
          print('[❗] Error processing WebSocket message: $e');
        }
      },
      onError: (error) {
        print('[🧯] WebSocket error: $error');
        disconnect();
        _scheduleReconnect();
      },
      onDone: () {
        print('[📴] WebSocket closed with code ${_channel?.closeCode}.');
        disconnect();
        _scheduleReconnect();
      },
    );
  }

  void disconnect() {
    if (_channel != null) {
      print('[🔌] Disconnecting WebSocket.');
      _channel?.sink.close();
      _channel = null;
      _isListening = false;
    }
  }

  void _scheduleReconnect() {
    Future.delayed(Duration(seconds: 5), () {
      print('[🔁] Reconnecting to WebSocket...');
      connect();
    });
  }

  /// Emit endCall event
  void emitEndCall(String user) {
    if (_channel != null) {
      final endCallData = json.encode({
        'type': 'endCall',
        'user': user,
      });

      print('[📤] Sending endCall event for user: $user');
      _channel!.sink.add(endCallData);
    } else {
      print('[⚠️] Tried to send endCall but WebSocket not connected.');
    }
  }

  /// Emit set_in_call event
  void emitSetInCall({
    required String username,
    required String inCallWith,
  }) {
    if (_channel != null) {
      final setCallData = json.encode({
        'type': 'set_in_call',
        'user': username,
        'in_call_with': inCallWith,
      });

      print('[📤] Sending set_in_call: $username <-> $inCallWith');
      _channel!.sink.add(setCallData);
    } else {
      print('[⚠️] WebSocket not connected. Cannot send set_in_call.');
    }
  }

  /// Listen for callEnded signal
  void listenToCallEvents({required CallEndedCallback onCallEnded}) {
    _onCallEnded = onCallEnded;
  }

  /// Cleanup listeners
  void removeCallListeners() {
    print('[🧹] Removing WebSocket listeners.');
    _onCallEnded = null;
    _channel?.sink.close();
    _channel = null;
    _isListening = false;
  }

  bool get isConnected => _channel != null && _channel!.closeCode == null;
}
