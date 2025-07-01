import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:map_tracker/services/auth_service.dart';
import 'package:map_tracker/services/navigation_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'toast_widget.dart';

class NavigationDrawerWidget extends StatelessWidget {
  const NavigationDrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService _authService = GetIt.I<AuthService>();
    final NavigationService _navigationService = GetIt.I<NavigationService>();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.amber),
            child: Text(
              'Map Tracker',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // Add navigation to settings page
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              _navigationService.pushNamed('/profile');
              // Add navigation to profile page
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context);
              try {
                await _authService.logout();
                if (!context.mounted) return;
                ToastWidget.show(
                  context: context,
                  title: "Logged out successfully",
                  subtitle: "See you soon!",
                  iconColor: Colors.black,
                  backgroundColor: Colors.green,
                  icon: Icons.logout,
                );
                _navigationService.pushReplacementNamed("/login");
              } catch (e) {
                Fluttertoast.showToast(
                  msg: 'Logout failed: $e',
                  toastLength: Toast.LENGTH_LONG,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  fontSize: 14.0,
                );
                debugPrint("Logout Error: $e");
              }
            },
          ),
        ],
      ),
    );
  }
}
