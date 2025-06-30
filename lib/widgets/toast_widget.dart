import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:delightful_toast/delight_toast.dart';

class ToastWidget {
  static void show({
    required BuildContext context,
    required String title,
    String? subtitle,
    IconData icon = Icons.arrow_right,
    Color iconColor = Colors.white,
    Color backgroundColor = Colors.deepPurple,
    DelightSnackbarPosition position = DelightSnackbarPosition.bottom,
  }) {
    DelightToastBar(
      position: position,
      autoDismiss: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white70),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).show(context);
  }
}
