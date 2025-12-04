import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;

  const ErrorDialog({
    super.key,
    this.title = 'エラー',
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            context.pop();
          },
          child: const Text('OK'),
        ),
      ],
    );
  }

  // Helper method to show the dialog
  static Future<void> show(BuildContext context, String message, {String title = 'エラー'}) async {
    await showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
      ),
    );
  }
}
