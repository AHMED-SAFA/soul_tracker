import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_tracker/services/share_service.dart';

Future<void> showGenerateCodeDialog({
  required BuildContext context,
  required ShareService shareService,
}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  final proceed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Warning'),
      content: const Text(
        'By sharing this code, others will be able to track your location.\n\n'
        'You can stop or modify tracking anytime later from the settings or tracking management screen.\n\n'
        'Do you want to proceed?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Continue'),
        ),
      ],
    ),
  );

  if (proceed != true) return;

  try {
    final code = await shareService.generateSharingCode();
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sharing Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this code with others to track your location:'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    code,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy Code',
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Code copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text('Valid for 2 hours'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  } catch (e) {
    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text('Error generating code: ${e.toString()}')),
    );
  }
}
