import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../di/injection.dart';
import '../../../../domain/repositories/auth_repository.dart';
import '../../../../router/app_router.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authRepo = getIt<AuthRepository>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final result = _isSignUp
        ? await authRepo.register(
            email: email,
            password: password,
            name: _nameController.text.trim().isNotEmpty
                ? _nameController.text.trim()
                : null,
          )
        : await authRepo.login(email: email, password: password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) => context.showSnackBar(failure.message, isError: true),
      (_) => context.go(AppRoutes.main),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : AppColors.scaffoldBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.pagePadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Logo / Title ─────────────────────────────────
                const SizedBox(height: 32),
                Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 56,
                  color: isDark ? Colors.white : AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'BudgetWise',
                  style: AppStyles.displayLarge.copyWith(
                    color: isDark ? Colors.white : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSignUp ? 'Create your account' : 'Welcome back',
                  style: AppStyles.bodySmall,
                ),
                const SizedBox(height: 40),

                // ── Form ─────────────────────────────────────────
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Name (sign-up only)
                      if (_isSignUp) ...[
                        TextFormField(
                          controller: _nameController,
                          style: AppStyles.inputText.copyWith(
                            color: isDark ? Colors.white : null,
                          ),
                          decoration: AppStyles.input(
                            label: 'Name',
                            hint: 'Enter your name',
                            prefix: const Icon(Icons.person_outline, size: 20),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email
                      TextFormField(
                        controller: _emailController,
                        style: AppStyles.inputText.copyWith(
                          color: isDark ? Colors.white : null,
                        ),
                        decoration: AppStyles.input(
                          label: 'Email',
                          hint: 'Enter your email',
                          prefix: const Icon(Icons.email_outlined, size: 20),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(value.trim())) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        style: AppStyles.inputText.copyWith(
                          color: isDark ? Colors.white : null,
                        ),
                        decoration: AppStyles.input(
                          label: 'Password',
                          hint: 'Enter your password',
                          prefix: const Icon(Icons.lock_outline, size: 20),
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: AppColors.textTertiary,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Password is required';
                          }
                          if (value.trim().length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: AppStyles.primaryButton,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_isSignUp ? 'Sign Up' : 'Sign In'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Toggle sign-in / sign-up ─────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSignUp
                          ? 'Already have an account?'
                          : "Don't have an account?",
                      style: AppStyles.bodySmall,
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() {
                                _isSignUp = !_isSignUp;
                                _formKey.currentState?.reset();
                              }),
                      child: Text(
                        _isSignUp ? 'Sign In' : 'Sign Up',
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
