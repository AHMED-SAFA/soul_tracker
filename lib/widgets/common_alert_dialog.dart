import 'package:flutter/material.dart';

class CommonAlertDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color titleColor;
  final Color iconColor;
  final String? okButtonText;
  final String? cancelButtonText;
  final VoidCallback? onOkButtonTap;
  final VoidCallback? onCancelButtonTap;
  final bool dismissible;

  const CommonAlertDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    this.titleColor = Colors.white,
    this.iconColor = Colors.white,
    this.okButtonText,
    this.cancelButtonText,
    this.onOkButtonTap,
    this.onCancelButtonTap,
    this.dismissible = true,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => dismissible,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 10,
        backgroundColor: backgroundColor,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.1),
                radius: 32,
                child: Icon(icon, size: 36, color: iconColor),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: titleColor.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  if (cancelButtonText != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            onCancelButtonTap ??
                            () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.6),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          cancelButtonText!,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  if (cancelButtonText != null && okButtonText != null)
                    const SizedBox(width: 12),
                  if (okButtonText != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            onOkButtonTap ?? () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: backgroundColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          okButtonText!,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: backgroundColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
