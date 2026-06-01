import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/user_entity.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _identifierFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isEmailMode = true; // true = email, false = NIK
  bool _rememberMe = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _loadSavedCredentials();
  }

  void _setupAnimation() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  void _loadSavedCredentials() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.rememberMe && authProvider.savedIdentifier.isNotEmpty) {
      _identifierController.text = authProvider.savedIdentifier;
      _rememberMe = true;
      final mode = authProvider.savedLoginMode;
      _isEmailMode = mode == 'email';
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    _identifierFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final authProvider = context.read<AuthProvider>();
    bool success;

    if (_isEmailMode) {
      success = await authProvider.loginWithEmail(
        email: _identifierController.text,
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );
    } else {
      success = await authProvider.loginWithNik(
        nik: _identifierController.text,
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );
    }

    if (!mounted) return;

    if (success) {
      final user = authProvider.currentUser!;
      if (user.role == UserRole.admin) {
        context.go(AppRoutes.adminDashboard);
      } else {
        context.go(AppRoutes.employeeDashboard);
      }
    } else {
      _showErrorSnackBar(authProvider.errorMessage ?? AppStrings.unknownError);
      authProvider.clearError();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.primaryCard,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _toggleLoginMode() {
    setState(() {
      _isEmailMode = !_isEmailMode;
      _identifierController.clear();
    });
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: AppColors.splashGradient),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      // Logo
                      const AppLogo(size: 72, showTagline: false),
                      const SizedBox(height: 40),
                      // Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withAlpha(230),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.primaryCard,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(77),
                              blurRadius: 40,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                AppStrings.loginTitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                AppStrings.loginSubtitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 28),

                              // Login mode toggle
                              _buildLoginModeToggle(),
                              const SizedBox(height: 20),

                              // Identifier Field
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: CustomTextField(
                                  key: ValueKey(_isEmailMode),
                                  label: _isEmailMode
                                      ? AppStrings.emailLabel
                                      : AppStrings.nikLabel,
                                  hint: _isEmailMode
                                      ? 'contoh@email.com'
                                      : '12345678',
                                  controller: _identifierController,
                                  focusNode: _identifierFocus,
                                  keyboardType: _isEmailMode
                                      ? TextInputType.emailAddress
                                      : TextInputType.number,
                                  prefixIcon: _isEmailMode
                                      ? Icons.email_outlined
                                      : Icons.badge_outlined,
                                  inputFormatters: _isEmailMode
                                      ? null
                                      : [FilteringTextInputFormatter.digitsOnly],
                                  maxLength: _isEmailMode ? null : 16,
                                  textInputAction: TextInputAction.next,
                                  onEditingComplete: () {
                                    _identifierFocus.unfocus();
                                    FocusScope.of(context)
                                        .requestFocus(_passwordFocus);
                                  },
                                  validator: (v) =>
                                      AppValidators.validateEmailOrNik(
                                          v, _isEmailMode),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Password Field
                              CustomTextField(
                                label: AppStrings.passwordLabel,
                                hint: '••••••••',
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                isPassword: true,
                                prefixIcon: Icons.lock_outlined,
                                textInputAction: TextInputAction.done,
                                onEditingComplete: _handleLogin,
                                validator: AppValidators.validatePassword,
                              ),
                              const SizedBox(height: 20),

                              // Remember Me + Forgot Password
                              Row(
                                children: [
                                  // Remember Me
                                  GestureDetector(
                                    onTap: () => setState(
                                        () => _rememberMe = !_rememberMe),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Checkbox(
                                            value: _rememberMe,
                                            onChanged: (v) => setState(
                                                () => _rememberMe = v ?? false),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          AppStrings.rememberMe,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  // Forgot Password
                                  TextButton(
                                    onPressed: () =>
                                        context.push(AppRoutes.forgotPassword),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      AppStrings.forgotPassword,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.secondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),

                              // Login Button
                              Consumer<AuthProvider>(
                                builder: (context, auth, _) {
                                  return CustomButton(
                                    label: AppStrings.loginButton,
                                    onPressed: _handleLogin,
                                    isLoading: auth.isLoading,
                                    leadingIcon: Icons.login_rounded,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Footer
                      Text(
                        '© 2025 APB Connect v${AppStrings.appVersion}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginModeToggle() {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildToggleButton(
            label: 'Email',
            icon: Icons.email_outlined,
            isSelected: _isEmailMode,
            onTap: _isEmailMode ? null : _toggleLoginMode,
          ),
          _buildToggleButton(
            label: 'NIK',
            icon: Icons.badge_outlined,
            isSelected: !_isEmailMode,
            onTap: !_isEmailMode ? null : _toggleLoginMode,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color:
                isSelected ? AppColors.secondary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? AppColors.white
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.white
                      : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
