// custom_app_bar.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:map_tracker/services/navigation_service.dart';
import '../services/share_service.dart';
import 'enter_code_widget.dart';
import 'generate_code_widget.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showEnterCodeButton;
  final bool showShareButton;
  final bool showBackButton;
  final Color backgroundColor;
  final Color titleColor;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showEnterCodeButton = true,
    this.showShareButton = true,
    this.showBackButton = true,
    this.backgroundColor = const Color(0xFF1A237E),
    this.titleColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final navigationService = GetIt.instance<NavigationService>();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor,
            backgroundColor.withOpacity(0.8),
            const Color(0xFF3949AB).withOpacity(0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AppBar(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: titleColor,
            fontSize: 20,
            letterSpacing: 0.8,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: showBackButton
            ? Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  color: titleColor,
                  onPressed: () {
                    navigationService.goBack();
                  },
                ),
              )
            : null,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (showEnterCodeButton)
            Container(
              margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const EnterCodeButton(),
            ),
          if (showShareButton)
            Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.share_outlined, size: 20),
                color: titleColor,
                tooltip: 'Create location tracker code',
                onPressed: () {
                  final shareService = ShareService();
                  showGenerateCodeDialog(
                    context: context,
                    shareService: shareService,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
