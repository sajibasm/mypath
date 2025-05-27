import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../constants/constants.dart';
import '../services/APIService.dart';
import '../services/StorageService.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _slideAnimation;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final LocalAuthentication auth = LocalAuthentication();

  bool _rememberWithBiometrics = false;
  bool _isAuthenticating = false;
  BiometricType? _availableBiometric;
  bool _biometricChecked = false;

  late final AnimationController _biometricAnimController;
  late final Animation<double> _biometricPulse;


  @override
  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.animationDuration,
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();

    _biometricAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _biometricPulse = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _biometricAnimController, curve: Curves.easeInOut),
    );

    _checkBiometricType();
  }


  @override
  @override
  void dispose() {
    _controller.dispose();
    _biometricAnimController.dispose(); // ✅ You missed this
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricType() async {
    final available = await auth.getAvailableBiometrics();
    // print('Available biometrics: $available');
    if (available.contains(BiometricType.face)) {
      _availableBiometric = BiometricType.face;
    } else if (available.contains(BiometricType.fingerprint)) {
      _availableBiometric = BiometricType.fingerprint;
    } else if (available.contains(BiometricType.strong)) {
      _availableBiometric = BiometricType.strong;
    } else if (available.contains(BiometricType.weak)) {
      _availableBiometric = BiometricType.weak;
    }

    setState(() {
      _biometricChecked = true;
    });
  }

  Future<bool> _authenticateWithBiometrics() async {
    final canCheck = await auth.canCheckBiometrics;
    final isDeviceSupported = await auth.isDeviceSupported();

    if (!canCheck || !isDeviceSupported) return false;

    final authenticated = await auth.authenticate(
      localizedReason: 'Scan your fingerprint or face to login',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );

    return authenticated;
  }

  Future<void> _handleBiometricLogin() async {
    setState(() => _isAuthenticating = true);

    final success = await _authenticateWithBiometrics();
    if (!success) {
      setState(() => _isAuthenticating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication failed.')),
      );
      return;
    }

    final credentials = await StorageService.loadCredentials();
    final email = credentials['email'];
    final password = credentials['password'];

    if (email == null || password == null) {
      setState(() => _isAuthenticating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved credentials found. Please login manually first.')),
      );
      return;
    }

    try {
      final result = await APIService.login(email: email, password: password);
      if (result['status'] == true) {
        await StorageService.saveUserInfo(result['user']);
        await StorageService.saveTokens(
          accessToken: result['access_token'],
          refreshToken: result['refresh_token'],
          accessExpires: result['access_token_expires_at'],
          refreshExpires: result['refresh_token_expires_at'],
        );
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['detail']), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Biometric login failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isAuthenticating = false);
    }
  }

  IconData getBiometricIcon() {
    switch (_availableBiometric) {
      case BiometricType.face:
        return Icons.face;
      case BiometricType.fingerprint:
      case BiometricType.weak:
        return Icons.fingerprint;
      case BiometricType.strong:
        return Icons.verified_user;
      default:
        return Icons.verified_user;
    }
  }

  String getBiometricLabel() {
    switch (_availableBiometric) {
      case BiometricType.face:
        return 'Login with Face ID';
      case BiometricType.fingerprint:
      case BiometricType.weak:
        return 'Login with Fingerprint';
      case BiometricType.strong:
        return 'Login with Biometric';
      default:
        return 'Login Securely';
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.mapPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Welcome', style: AppTextStyles.header),
              ),
            ),
          ),
          Expanded(
            flex: 8,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _opacityAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.mapPadding),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          cursorColor: Colors.black,
                          decoration: const InputDecoration(
                            labelText: 'Email address',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,63}$');
                            if (!emailRegex.hasMatch(value)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            if (_formKey.currentState != null) {
                              _formKey.currentState!.validate();
                            }
                          },
                        ),

                        const SizedBox(height: 20),
                        TextFormField(
                          controller: passwordController,
                          obscureText: !_isPasswordVisible,
                          cursorColor: Colors.black,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            if (_formKey.currentState != null) {
                              _formKey.currentState!.validate();
                            }
                          },
                        ),

                        const SizedBox(height: 30),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _rememberWithBiometrics,
                          onChanged: (value) {
                            setState(() {
                              _rememberWithBiometrics = value ?? false;
                            });
                          },
                          title: const Text('Remember me with biometrics'),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        const SizedBox(height: 10),

                        ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Login', style: AppTextStyles.primaryButton),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.pushNamed(context, '/signup'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Sign Up', style: AppTextStyles.outlinedButton),
                        ),
                        const SizedBox(height: 12),
                        if (_biometricChecked && _availableBiometric != null)
                          AnimatedBuilder(
                            animation: _biometricAnimController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _isAuthenticating ? _biometricPulse.value : 1.0,
                                child: child,
                              );
                            },
                            child: ElevatedButton.icon(
                              onPressed: _isAuthenticating ? null : _handleBiometricLogin,
                              icon: Icon(getBiometricIcon(), size: 24, color: Colors.white),
                              label: Text(
                                getBiometricLabel(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/reset-password'),
                            child: const Text('Reset Password', style: AppTextStyles.link),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      final result = await APIService.login(email: email, password: password);
      if (result['status'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(result['detail'], style: const TextStyle(color: Colors.white))),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await StorageService.saveUserInfo(result['user']);
      await StorageService.saveTokens(
        accessToken: result['access_token'],
        refreshToken: result['refresh_token'],
        accessExpires: result['access_token_expires_at'],
        refreshExpires: result['refresh_token_expires_at'],
      );

      if (_rememberWithBiometrics) {
        await StorageService.saveCredentials(email, password);
      }else{
        await StorageService.clearCredentials();
      }

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
