import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/data/mock_auth_repository.dart';
import '../features/auth/state/auth_controller.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class CongressApp extends StatefulWidget {
  const CongressApp({super.key, this.authController});

  final AuthController? authController;

  @override
  State<CongressApp> createState() => _CongressAppState();
}

class _CongressAppState extends State<CongressApp> {
  late final AuthController _authController;
  late final bool _ownsAuthController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _ownsAuthController = widget.authController == null;
    _authController =
        widget.authController ?? AuthController(MockAuthRepository());
    _router = createRouter(_authController);
  }

  @override
  void dispose() {
    _router.dispose();
    if (_ownsAuthController) {
      _authController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: _authController,
      child: MaterialApp.router(
        title: 'Nestlé Medical Congress',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.congress(),
        routerConfig: _router,
      ),
    );
  }
}
