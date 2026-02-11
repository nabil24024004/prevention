import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name')));
      return;
    }
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'username': _nameController.text.trim(),
          'display_name': _nameController.text.trim(), // For Auth display name
        },
      );

      if (mounted) {
        if (response.user != null) {
          // Update user profile with display name
          try {
            await Supabase.instance.client.auth.updateUser(
              UserAttributes(
                data: {
                  'display_name': _nameController.text.trim(),
                  'username': _nameController.text.trim(),
                },
              ),
            );
          } catch (_) {
            // Continue even if profile update fails
          }

          // Check if session exists (auto-login)
          if (response.session != null) {
            // Explicitly creating user record to ensure name is saved
            try {
              await Supabase.instance.client.from('users').upsert({
                'id': response.user!.id,
                'username': _nameController.text.trim(),
                'email': _emailController.text.trim(),
                'start_date': DateTime.now().toIso8601String(),
                'current_streak_days': 0,
                'best_streak_days': 0,
              });
            } catch (_) {
              // Fail silently, trigger might have handled it
            }
            if (mounted) context.go('/dashboard');
          } else {
            // Confirm email required
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Success! Please check your email to confirm your account.',
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 4),
                ),
              );
              context.go('/login'); // Return to login to wait for click
            }
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign Up Failed: ${e.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/welcome');
            }
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Account',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start your journey to freedom today.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 48),

              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Sign Up',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 50), // Bottom padding to prevent cutoff
            ],
          ),
        ),
      ),
    );
  }
}
