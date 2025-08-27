import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../routes/navRoutes.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLogin = true;
  bool _busy = false;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final supa = Supabase.instance.client;

    try {
      if (_isLogin) {
        await supa.auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        final res = await supa.auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {'full_name': _fullName.text.trim()},
        );
        final user = res.user ?? supa.auth.currentUser;
        if (user != null) {
          await supa.from('profiles').upsert({
            'user_id': user.id,
            'full_name': _fullName.text.trim(),
            'role': 'customer',
          }, onConflict: 'user_id');
        }
      }
      if (mounted) {
        Navigator.pushReplacementNamed(context, NavRoutes.homePage);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isLogin ? 'Signed in!' : 'Account created!')),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Auth error: ${e.message}')));
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Database error: ${e.message}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Sign in' : 'Sign in / Sign up')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (!_isLogin)
                  TextFormField(
                    controller: _fullName,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (v) => (v == null || v.trim().length < 3)
                        ? 'Enter name'
                        : null,
                  ),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Enter valid email'
                      : null,
                ),
                TextFormField(
                  controller: _password,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Min 6 chars' : null,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _submit,
                  child: Text(_isLogin ? 'Sign in' : 'Create account'),
                ),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin
                        ? "Don't have an account? Sign up"
                        : "Already have an account? Sign in",
                  ),
                ),
                if (_busy) const SizedBox(height: 12),
                if (_busy) const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
