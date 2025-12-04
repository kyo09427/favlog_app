import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text(
          '設定画面',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
