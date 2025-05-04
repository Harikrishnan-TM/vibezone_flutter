import 'package:flutter/material.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            onTap: () {}, // Add actual navigation or URL opening
          ),
          ListTile(
            leading: const Icon(Icons.rule),
            title: const Text('Terms of Use'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Community Guidelines'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
