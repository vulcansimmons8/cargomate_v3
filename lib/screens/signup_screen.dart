import 'package:cargomate_v3/viewmodel/role_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../routes/navRoutes.dart';
import '../widgets/widgets.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _nameCtl = TextEditingController();
  final _phoneCtl = TextEditingController();

  bool _busy = false;
  bool _passwordVisible = false;
  String _role = 'customer';

  @override
  void dispose() {
    _emailCtl.dispose();
    _passwordCtl.dispose();
    _nameCtl.dispose();
    _phoneCtl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      final supa = Supabase.instance.client;

      final email = _emailCtl.text.trim();
      final password = _passwordCtl.text.trim();

      // Sign up the user
      final res = await supa.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': _nameCtl.text.trim()},
      );

      final user = res.user ?? supa.auth.currentUser;

      if (user != null) {
        // Insert or update user profile
        await supa.from('profiles').upsert({
          'user_id': user.id,
          'full_name': _nameCtl.text.trim(),
          'phone_number': _phoneCtl.text.trim(),
          'role': _role,
        }, onConflict: 'user_id');

        // Update RoleViewModel immediately
        if (mounted) {
          final roleVM = context.read<RoleViewModel>();
          roleVM.setRole(_role);
        }
      }

      if (!mounted) return;

      AppSnack.show(context, 'Account created successfully!');

      // Navigate based on role
      if (_role == 'customer') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          NavRoutes.homePage,
          (route) => false,
        );
      } else if (_role == 'driver' || _role == 'bikeRider') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          NavRoutes
              .driverHome, // You could have a separate route if needed for bikeRider
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        AppSnack.show(context, 'Auth error: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        AppSnack.show(context, 'Unexpected error: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up'), centerTitle: true),
      body: LoadingOverlay(
        show: _busy,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ✅ Email
                TextFormField(
                  controller: _emailCtl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter your email' : null,
                ),
                const SizedBox(height: 12),

                // ✅ Password with visibility toggle
                TextFormField(
                  controller: _passwordCtl,
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                    ),
                  ),
                  validator: (v) => v != null && v.length < 6
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
                const SizedBox(height: 12),

                // ✅ Full Name
                TextFormField(
                  controller: _nameCtl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 12),

                // ✅ Phone Number
                TextFormField(
                  controller: _phoneCtl,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter your phone number' : null,
                ),
                const SizedBox(height: 12),

                // ✅ Role Dropdown
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(
                      value: 'customer',
                      child: Text('Customer'),
                    ),
                    DropdownMenuItem(value: 'driver', child: Text('Driver')),
                    DropdownMenuItem(
                      value: 'bikeRider',
                      child: Text('Bike Rider'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _role = v ?? 'customer'),
                ),

                const SizedBox(height: 24),

                // ✅ Submit Button
                PrimaryButton(
                  label: 'Create Account',
                  onPressed: _signUp,
                  loading: _busy,
                ),
                const SizedBox(height: 16),

                // ✅ Already have an account
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, NavRoutes.signIn);
                    },
                    child: const Text(
                      'Already have an account? Sign In',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
