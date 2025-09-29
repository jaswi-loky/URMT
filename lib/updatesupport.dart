import 'package:flutter/material.dart';
import 'updateinapp.dart';


Future<void> startSafeUpdateDialog(BuildContext context, String apkUrl) async {
  final updater = ApkUpdater();
  final progressNotifier = ValueNotifier<double>(0.0);
  bool isCancelled = false;

  // Show progress dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text("Updating..."),
        content: ValueListenableBuilder<double>(
          valueListenable: progressNotifier,
          builder: (context, progress, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 16),
                Text("${(progress * 100).toStringAsFixed(0)}%"),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    isCancelled = true;
                  },
                  child: const Text("Cancel"),
                ),
              ],
            );
          },
        ),
      );
    },
  );

  // Start download after dialog is shown
  await Future.delayed(Duration.zero);
  try {
    await updater.downloadAndInstall(
      apkUrl: apkUrl,
      onProgress: (p) {
        if (isCancelled) return;
        progressNotifier.value = p;
      },
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: $e")),
      );
    }
  }

  // Close dialog safely
  if (progressNotifier.hasListeners) progressNotifier.dispose();
  if (context.mounted) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
