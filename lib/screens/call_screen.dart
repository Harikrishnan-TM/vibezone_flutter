import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class CallScreen extends StatefulWidget {
  final String otherUser;
  final int walletCoins;
  final bool isInitiator;

  const CallScreen({
    Key? key,
    required this.otherUser,
    required this.walletCoins,
    required this.isInitiator,
  }) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _accepted = false;
  late int _currentCoins;
  late SocketService _socketService;
  String? _currentUser; // Changed to nullable

  @override
  void initState() {
    super.initState();
    _currentCoins = widget.walletCoins;
    _socketService = SocketService.getInstance();
    _socketService.listenToCallEvents(onCallEnded: _handleRemoteEndCall);
    _initialize();
  }

  Future<void> _initialize() async {
    _currentUser = await ApiService.getCurrentUsername();

    if (_currentUser == null) {
      debugPrint('Could not retrieve current username.');
      _showErrorAndExit();
      return;
    }

    _socketService.emitSetInCall(
      username: _currentUser!,
      inCallWith: widget.otherUser,
    );

    await _setUserInCallStatus(widget.otherUser);
    await _checkPermissions();
  }

  Future<void> _setUserInCallStatus(String username) async {
    try {
      await ApiService.setUserInCallWith(username);
    } catch (e) {
      debugPrint('Error updating call status: $e');
    }
  }

  Future<void> _checkPermissions() async {
    final micStatus = await Permission.microphone.request();
    final cameraStatus = await Permission.camera.request();

    if (micStatus.isGranted && cameraStatus.isGranted) {
      if (!widget.isInitiator) {
        _acceptIncomingCall();
      } else {
        _startTimer();
      }
    } else {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
            'To make or receive calls, we need access to your microphone and camera. Please grant the necessary permissions.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _acceptIncomingCall() async {
    try {
      final response = await ApiService.acceptCall(widget.otherUser);
      if (response != null && response['accepted'] == true) {
        setState(() => _accepted = true);
        _startTimer();
      } else {
        debugPrint('Call not accepted');
        _closeScreen();
      }
    } catch (e) {
      debugPrint('Error accepting call: $e');
      _closeScreen();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      setState(() {
        _secondsElapsed++;
      });

      if (_secondsElapsed % 60 == 0) {
        await _deductCoins();
      }
    });
  }

  Future<void> _deductCoins() async {
    try {
      final response = await ApiService.deductCoins();
      if (response != null) {
        if (response['success'] == true) {
          setState(() {
            _currentCoins = response['coins'] ?? _currentCoins;
          });
        }
        if (response['end_call'] == true) {
          debugPrint('Coins depleted. Ending call.');
          _endCall();
        }
      }
    } catch (e) {
      debugPrint('Error deducting coins: $e');
    }
  }

  Future<void> _endCall() async {
    try {
      _timer?.cancel();
      await ApiService.endCall(widget.otherUser);
      _socketService.emitEndCall(widget.otherUser);

      if (_currentUser != null) {
        _socketService.emitSetInCall(
          username: _currentUser!,
          inCallWith: '',
        );
        await _setUserInCallStatus('');
      }
    } catch (e) {
      debugPrint('Error ending call: $e');
    } finally {
      _closeScreen();
    }
  }

  void _handleRemoteEndCall() {
    debugPrint('Call ended by other user.');
    if (mounted) {
      _timer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Call ended by the other user.')),
      );
      _closeScreen();
    }
  }

  void _closeScreen() {
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showErrorAndExit() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: const Text('Could not determine user identity. Please try again later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    ).then((_) => _closeScreen());
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return "$minutes:${secs.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer?.cancel();
    _socketService.removeCallListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Call Page'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Text(
              "On Call with ${widget.otherUser}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            if (widget.isInitiator || _accepted)
              Text(
                "Call Time: ${_formatDuration(_secondsElapsed)}",
                style: const TextStyle(fontSize: 18),
              )
            else
              const Text(
                "Waiting for acceptance...",
                style: TextStyle(fontSize: 18, color: Colors.orange),
              ),
            const SizedBox(height: 20),
            Text(
              "Coins Left: $_currentCoins",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _endCall,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("End Call"),
            ),
            const Spacer(),
            const Text(
              "Local Audio Stream",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            const Text(
              "Remote Audio Stream",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
