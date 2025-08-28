import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../routes/navRoutes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // Small splash delay (branding) + a moment for Supabase to hydrate the session
    await Future.delayed(const Duration(seconds: 1));

    final supa = Supabase.instance.client;
    final user = supa.auth.currentUser;

    if (!mounted) return;

    if (user == null) {
      // Not signed in -> Sign In (or Onboarding if you prefer)
      Navigator.pushReplacementNamed(context, NavRoutes.signIn);
      return;
    }

    try {
      // Look up profile row for this user (customize columns to your schema)
      final profile = await supa
          .from('profiles')
          .select('id, full_name, phone_number, role')
          .eq('id', user.id)
          .maybeSingle();

      final String fullName = (profile?['full_name'] ?? '').toString().trim();
      final String phone = (profile?['phone_number'] ?? '').toString().trim();
      // Mark as "needs setup" if row is missing or key fields are empty
      final bool needsSetup =
          (profile == null) || fullName.isEmpty || phone.isEmpty;

      if (needsSetup) {
        // Pass a phone hint if available; your route builder treats null specially,
        // so pass '' (empty) instead of null.
        final phoneHint = user.phone ?? '';
        Navigator.pushReplacementNamed(
          context,
          NavRoutes.signUp,
          arguments: phoneHint,
        );
      }
    } catch (_) {
      // If profile query fails for any reason, be safe and send them to setup.
      final phoneHint = Supabase.instance.client.auth.currentUser?.phone ?? '';
      Navigator.pushReplacementNamed(
        context,
        NavRoutes.signUp,
        arguments: phoneHint,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping, size: 72, color: Colors.deepPurple),
            SizedBox(height: 16),
            Text(
              'CargoMate',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
