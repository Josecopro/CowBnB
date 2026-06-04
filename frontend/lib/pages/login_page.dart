import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../design_tokens.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Ingresa correo y contraseña');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final profile = await _authService.getProfile();
      if (!mounted) return;

      if (profile != null) {
        if (profile.role == 'owner') {
          context.go('/owner');
        } else {
          context.go('/renter');
        }
      } else {
        context.go('/register-role');
      }
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'No existe una cuenta con este correo';
          break;
        case 'wrong-password':
          msg = 'Contraseña incorrecta';
          break;
        case 'invalid-credential':
          msg = 'Credenciales inválidas';
          break;
        case 'too-many-requests':
          msg = 'Demasiados intentos. Intenta más tarde';
          break;
        default:
          msg = 'Error al iniciar sesión';
      }
      setState(() => _errorMessage = msg);
    } catch (e) {
      setState(() => _errorMessage = 'Error al iniciar sesión');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Ingresa tu correo para restablecer la contraseña');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Correo de restablecimiento enviado')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error al enviar correo de restablecimiento');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        title: const Text('Iniciar Sesión'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 48),
            Text(
              'Bienvenido de vuelta',
              style: AppTextStyles.display,
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresa tus credenciales para continuar',
              style: AppTextStyles.body.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: 48),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Correo electronico',
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.inkMuted,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                prefixIcon: const Icon(Icons.email, color: AppColors.inkMuted),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Contrasena',
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.inkMuted,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                prefixIcon: const Icon(Icons.lock, color: AppColors.inkMuted),
              ),
              obscureText: true,
              onSubmitted: (_) => _handleLogin(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Iniciar Sesion',
                        style: AppTextStyles.label.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _handlePasswordReset,
              child: Text(
                '¿Olvidaste tu contrasena?',
                style: AppTextStyles.label.copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('¿No tienes cuenta?',
                    style: AppTextStyles.body.copyWith(color: AppColors.inkMuted)),
                TextButton(
                  onPressed: () => context.go('/register-role'),
                  child: Text(
                    'Registrate',
                    style: AppTextStyles.label.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
