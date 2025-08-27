import 'package:flutter/material.dart';
import '../routes/navRoutes.dart';

class AuthChoiceScreen extends StatelessWidget {
  const AuthChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Sign-in Method')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: () {
                // Email/password (our implemented flow)
                Navigator.pushReplacementNamed(context, NavRoutes.signIn);
              },
              child: const Text('Use Email & Password'),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () {
                // TODO: wire up phone-OTP flow, then go to OTP page
                Navigator.pushNamed(context, NavRoutes.otpVerification);
              },
              child: const Text('Use Phone (OTP)'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                // TODO: social providers (Google/Apple) if you enable them later
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Social login coming soon…')),
                );
              },
              child: const Text('Continue with Google (demo)'),
            ),
          ],
        ),
      ),
    );
  }
}
