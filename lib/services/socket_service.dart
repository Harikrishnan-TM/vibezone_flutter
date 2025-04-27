import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class SocketService {
  final Function onIncomingCall;
  final Function(List<dynamic>) onRefreshUsers;
  WebSocketChannel? _channel;

  SocketService({required this.onIncomingCall, required this.onRefreshUsers});

  void connect() {
    final uri = Uri.parse('ws://YOUR_SERVER_ADDRESS/ws/online-users/');
    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen((event) {
      final data = json.decode(event);
      if (data['type'] == 'call') {
        onIncomingCall();
      } else if (data['type'] == 'refresh') {
        List<dynamic> newUsers = data['payload']['users'];
        onRefreshUsers(newUsers);
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket closed.');
    });
  }

  void disconnect() {
    _channel?.sink.close();
  }
}
