import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/auth_page_scaffold.dart';
import '../state/auth_controller.dart';
import '../data/auth_repository.dart';
import '../widgets/auth_switch_prompt.dart';
import '../widgets/simulated_social_auth_sheet.dart';
import 'widgets/login_feature_pills.dart';
import 'widgets/login_form_card.dart';
import 'widgets/login_hero_header.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  var _obscurePassword = true;
  var _autovalidateMode = AutovalidateMode.disabled;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _applyInitialEmail(widget.initialEmail);
  }

  @override
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final email = widget.initialEmail?.trim() ?? '';
    if (email.isNotEmpty && email != oldWidget.initialEmail?.trim()) {
      _applyInitialEmail(email);
    }
  }

  void _applyInitialEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return;
    _emailController.text = email;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _autovalidateMode = AutovalidateMode.onUserInteraction;
      _errorMessage = null;
    });
    if (!_formKey.currentState!.validate()) return;

    try {
      await AuthScope.of(context).signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    }
  }

  Future<void> _showSocialSignInSheet() {
    return showSimulatedSocialAuthSheet(
      context: context,
      title: 'Google sign-in unavailable',
      message:
          'Google and Apple sign-in are not configured for this assessment. Use email and password.',
      dismissLabel: 'OK',
      onError: (message) {
        if (!mounted) return;
        setState(() => _errorMessage = message);
      },
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController(text: _emailController.text);
    try {
      final sent = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Reset password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter the email on your attendee profile. No email will be sent.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(hintText: 'Email address'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Send link'),
              ),
            ],
          );
        },
      );
      if (!mounted || sent != true) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No reset email was sent.')));
    } finally {
      emailController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return AuthPageScaffold(
      child: Column(
        children: [
          const LoginHeroHeader(),
          const SizedBox(height: 12),
          LoginFormCard(
            formKey: _formKey,
            emailController: _emailController,
            passwordController: _passwordController,
            autovalidateMode: _autovalidateMode,
            obscurePassword: _obscurePassword,
            loading: auth.isLoading,
            errorMessage: _errorMessage,
            onToggleObscure: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
            onSignIn: _signIn,
            onGoogle: _showSocialSignInSheet,
            onApple: _showSocialSignInSheet,
            onForgotPassword: _showForgotPasswordDialog,
          ),
          const SizedBox(height: 18),
          AuthSwitchPrompt(
            prompt: "Don't have an account? ",
            actionLabel: 'Create Account',
            showArrow: true,
            onAction: auth.isLoading
                ? null
                : () => context.push(AppRoutes.register),
          ),
          const SizedBox(height: 22),
          const LoginFeaturePills(),
        ],
      ),
    );
  }
}
