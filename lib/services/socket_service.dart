import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

typedef CallCallback = void Function();
typedef RefreshCallback = void Function(List<dynamic>);

class SocketService {
  static final SocketService _instance = SocketService._internal();

  WebSocketChannel? _channel;
  CallCallback? _onIncomingCall;
  RefreshCallback? _onRefreshUsers;

  SocketService._internal();

  factory SocketService.getInstance() => _instance;

  // Allow registration of callbacks (optional but useful for pages like HomeScreen)
  void registerCallbacks({
    required CallCallback onIncomingCall,
    required RefreshCallback onRefreshUsers,
  }) {
    _onIncomingCall = onIncomingCall;
    _onRefreshUsers = onRefreshUsers;
  }

  void connect() {
    if (_channel != null) return; // Prevent double connection

    final wsUrl = dotenv.env['SOCKET_URL'] ?? 'ws://localhost:8000/ws/online-users/';
    final uri = Uri.parse(wsUrl);

    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen(
      (event) {
        final data = json.decode(event);
        if (data['type'] == 'call') {
          _onIncomingCall?.call();
        } else if (data['type'] == 'refresh') {
          List<dynamic> newUsers = data['payload']['users'];
          _onRefreshUsers?.call(newUsers);
        }
      },
      onError: (error) {
        print('WebSocket error: $error');
        disconnect();
      },
      onDone: () {
        print('WebSocket closed.');
        disconnect();
      },
    );
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void reconnect() {
    print("Attempting to reconnect...");
    disconnect();
    connect();
  }

  bool get isConnected => _channel != null && _channel!.closeCode == null;
}
