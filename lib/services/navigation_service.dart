import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static BuildContext? get context => navigatorKey.currentContext;

  static Future<dynamic> navigateTo(String routeName, {dynamic arguments}) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('NavigationService: Context is null');
      return Future.value(null);
    }
    return Navigator.of(context).pushNamed(
      routeName,
      arguments: arguments,
    );
  }

  static void pop<T>([T? result]) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('NavigationService: Context is null');
      return;
    }
    if (Navigator.canPop(context)) {
      Navigator.pop(context, result);
    }
  }

  static bool canPop() {
    final context = navigatorKey.currentContext;
    if (context == null) return false;
    return Navigator.canPop(context);
  }

  static Future<dynamic> pushReplacement(String routeName,
      {dynamic arguments}) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('NavigationService: Context is null');
      return Future.value(null);
    }
    return Navigator.of(context).pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
  }

  static Future<dynamic> pushAndRemoveUntil(String routeName,
      {dynamic arguments}) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('NavigationService: Context is null');
      return Future.value(null);
    }
    return Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (Route<dynamic> route) => false,
      arguments: arguments,
    );
  }
}
