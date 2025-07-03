import 'package:flutter/material.dart';
import 'package:map_tracker/widgets/toast_widget.dart';
import '../services/share_service.dart';

class EnterCodeButton extends StatelessWidget {
  const EnterCodeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.qr_code),
      tooltip: 'Enter tracking code',
      onPressed: () => _showEnterCodeDialog(context),
    );
  }

  Future<void> _showEnterCodeDialog(BuildContext context) async {
    final shareService = ShareService();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final textController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Sharing Code'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Enter 6-digit code',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final code = textController.text.trim();
              if (code.isEmpty) return;

              final validation = await shareService.validateSharingCode(code);
              if (context.mounted) {
                if (validation == null) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Invalid or expired code')),
                  );
                  return;
                }

                Navigator.pop(context);
                ToastWidget.show(
                  context: context,
                  title: "Code connected successfully!",
                  icon: Icons.done_all,
                  backgroundColor: Colors.greenAccent,
                  iconColor: Colors.black,
                );

                // Optional: Trigger reload logic here via callback if needed
              }
            },
            child: const Text('Track'),
          ),
        ],
      ),
    );
  }
}
