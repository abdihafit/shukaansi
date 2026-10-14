import 'package:flutter/widgets.dart';

import '../services/auth_service.dart';

class AuthScope extends InheritedWidget {
  const AuthScope({super.key, required this.service, required super.child});
  final AuthService service;
  static AuthService of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()?.service ??
      const UnconfiguredAuthService();
  @override
  bool updateShouldNotify(AuthScope oldWidget) => service != oldWidget.service;
}
