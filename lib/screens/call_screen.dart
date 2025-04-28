import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart'; // ✅ API Service import

class CallScreen extends StatefulWidget {
  final String otherUser;   // Username of the user we are talking to
  final int walletCoins;    // Current user's starting coins
  final bool isInitiator;   // Whether I started the call

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

  @override
  void initState() {
    super.initState();
    _currentCoins = widget.walletCoins;

    if (!widget.isInitiator) {
      _acceptIncomingCall(); // If not initiator, wait for call acceptance
    } else {
      _startTimer(); // If initiator, start call immediately
    }
  }

  // Accept incoming call
  Future<void> _acceptIncomingCall() async {
    try {
      final response = await ApiService.acceptCall(widget.otherUser);
      if (response != null && response['accepted'] == true) {
        setState(() {
          _accepted = true;
        });
        _startTimer();
      } else {
        debugPrint('❌ Call not accepted');
        _closeScreen();
      }
    } catch (e) {
      debugPrint('⚠️ Error accepting call: $e');
      _closeScreen();
    }
  }

  // Start call timer
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

  // Deduct coins every minute
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
          debugPrint('❌ Coins over. Ending call.');
          _endCall();
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error deducting coins: $e');
    }
  }

  // End the call
  Future<void> _endCall() async {
    try {
      _timer?.cancel();
      await ApiService.endCall(widget.otherUser);
    } catch (e) {
      debugPrint('⚠️ Error ending call: $e');
    } finally {
      _closeScreen();
    }
  }

  // Close screen safely
  void _closeScreen() {
    if (mounted) {
      Navigator.pop(context);
    }
  }

  // Format seconds into mm:ss
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return "$minutes:${secs.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer?.cancel();
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
