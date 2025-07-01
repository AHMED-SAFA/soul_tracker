import 'package:flutter/material.dart';
import 'package:map_tracker/pages/authPages/login_page.dart';
import 'package:map_tracker/pages/authPages/register_page.dart';
import 'package:map_tracker/pages/homePages/home_page.dart';
import 'package:map_tracker/pages/homePages/user_profile.dart';

class NavigationService {
  late GlobalKey<NavigatorState> _navigatorKey;

  final Map<String, Widget Function(BuildContext)> _routes = {
    "/login": (context) => const Login(),
    "/register": (context) => const RegisterPage(),
    "/home": (context) => const HomePage(),
    "/profile": (context) => const UserProfile(),
  };

  GlobalKey<NavigatorState>? get navigatorKey {
    return _navigatorKey;
  }

  Map<String, Widget Function(BuildContext)> get routes {
    return _routes;
  }

  NavigationService() {
    _navigatorKey = GlobalKey<NavigatorState>();
  }

  void pushNamed(String routeName) {
    _navigatorKey.currentState?.pushNamed(routeName);
  }

  void pushReplacementNamed(String routeName) {
    _navigatorKey.currentState?.pushReplacementNamed(routeName);
  }

  void goBack() {
    _navigatorKey.currentState?.pop();
  }

  void push(MaterialPageRoute route) {
    _navigatorKey.currentState?.push(route);
  }
}
