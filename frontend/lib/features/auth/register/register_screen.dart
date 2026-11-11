import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/auth_card.dart';
import '../../../core/widgets/auth_page_scaffold.dart';
import '../../../core/widgets/congress_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/social_auth_row.dart';
import '../auth_validators.dart';
import '../data/auth_repository.dart';
import '../state/auth_controller.dart';
import '../widgets/auth_switch_prompt.dart';
import '../widgets/simulated_social_auth_sheet.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _organizationController = TextEditingController();
  final _passwordController = TextEditingController();

  var _obscurePassword = true;
  var _acceptedTerms = false;
  var _autovalidateMode = AutovalidateMode.disabled;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _organizationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _autovalidateMode = AutovalidateMode.onUserInteraction;
      _errorMessage = null;
    });

    final formValid = _formKey.currentState!.validate();
    if (!_acceptedTerms) {
      setState(
        () => _errorMessage =
            'Please agree to the congress terms before creating a profile.',
      );
      return;
    }
    if (!formValid) return;

    try {
      await AuthScope.of(context).register(
        RegistrationDraft(
          fullName: _nameController.text,
          email: _emailController.text,
          organization: _organizationController.text,
          password: _passwordController.text,
        ),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    }
  }

  Future<void> _showSocialSignUpSheet() {
    return showSimulatedSocialAuthSheet(
      context: context,
      title: 'Simulated social sign-up',
      message:
          'Google and Apple are not connected. Continue as the demo attendee, or use the form. No real account is created.',
      dismissLabel: 'Use the form instead',
      onError: (message) {
        if (!mounted) return;
        setState(() => _errorMessage = message);
      },
    );
  }

  Future<void> _showTermsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Congress terms'),
          content: const SingleChildScrollView(
            child: Text(
              'Sample congress terms for this demo.\n\n'
              'Please review attendee guidelines before creating a profile. A full privacy policy would appear here in a production congress app.',
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    return AuthPageScaffold(
      child: Column(
        children: [
          const Text(
            'Join the',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const Text(
            'NESTLÉ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              height: 1.05,
              letterSpacing: 0.4,
            ),
          ),
          const Text(
            'CONGRESS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              height: 1.05,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Create your attendee profile and access\nsessions, resources, voting and Q&A.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 14.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          AuthCard(
            child: Form(
              key: _formKey,
              autovalidateMode: _autovalidateMode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CongressTextField(
                    controller: _nameController,
                    enabled: !auth.isLoading,
                    hintText: 'Full name',
                    prefixIcon: Icons.person_outline_rounded,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    validator: AuthValidators.fullName,
                  ),
                  const SizedBox(height: 12),
                  CongressTextField(
                    controller: _emailController,
                    enabled: !auth.isLoading,
                    hintText: 'Email address',
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: AuthValidators.email,
                  ),
                  const SizedBox(height: 12),
                  CongressTextField(
                    controller: _organizationController,
                    enabled: !auth.isLoading,
                    hintText: 'Hospital / Organization',
                    prefixIcon: Icons.apartment_outlined,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.organizationName],
                    validator: AuthValidators.organization,
                  ),
                  const SizedBox(height: 12),
                  CongressTextField(
                    controller: _passwordController,
                    enabled: !auth.isLoading,
                    hintText: 'Create password',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onSubmitted: (_) => _register(),
                    validator: AuthValidators.password,
                    suffix: IconButton(
                      onPressed: auth.isLoading
                          ? null
                          : () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                      tooltip: _obscurePassword
                          ? 'Show password'
                          : 'Hide password',
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _acceptedTerms,
                          activeColor: AppColors.accentBlue,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          side: const BorderSide(
                            color: AppColors.checkboxBorder,
                            width: 1.4,
                          ),
                          onChanged: auth.isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _acceptedTerms = value ?? false;
                                    if (_acceptedTerms) _errorMessage = null;
                                  });
                                },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: _showTermsDialog,
                          child: const Text.rich(
                            TextSpan(
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.35,
                              ),
                              children: [
                                TextSpan(text: 'I agree to the congress '),
                                TextSpan(
                                  text:
                                      'terms, privacy policy and attendee guidelines.',
                                  style: TextStyle(
                                    color: AppColors.iconBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  GradientButton(
                    label: 'Create Account',
                    icon: Icons.person_add_alt_1_rounded,
                    showArrow: false,
                    loading: auth.isLoading,
                    gradient: AppColors.createAccountButton,
                    onPressed: auth.isLoading ? null : _register,
                  ),
                  const SizedBox(height: 16),
                  SocialAuthRow(
                    dividerLabel: 'OR SIGN UP WITH',
                    simpleGoogleMark: true,
                    onGoogle: auth.isLoading ? null : _showSocialSignUpSheet,
                    onApple: auth.isLoading ? null : _showSocialSignUpSheet,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          AuthSwitchPrompt(
            prompt: 'Already have an account? ',
            actionLabel: 'Sign In',
            onAction: auth.isLoading ? null : () => context.go(AppRoutes.login),
          ),
        ],
      ),
    );
  }
}
