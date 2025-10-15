import 'package:flutter/material.dart';

class ErrorReporter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<void> showError(
    String title,
    Object error, [
    StackTrace? stack,
  ]) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final message = error.toString();
    final details = stack?.toString() ?? '';
    final text = details.isEmpty ? message : '$message\n\n$details';

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: SelectableText(text),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
