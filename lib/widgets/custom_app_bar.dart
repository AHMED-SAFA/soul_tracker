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
    this.backgroundColor = Colors.amber,
    this.titleColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    final navigationService = GetIt.instance<NavigationService>();

    return AppBar(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600,color: titleColor)),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_outlined),
              onPressed: () {
                navigationService.goBack();
              },
            )
          : null,
      backgroundColor: backgroundColor,
      actions: [
        if (showEnterCodeButton) const EnterCodeButton(),
        if (showShareButton)
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Create location tracker code',
            onPressed: () {
              final shareService = ShareService();
              showGenerateCodeDialog(
                context: context,
                shareService: shareService,
              );
            },
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
