import 'package:flutter/material.dart';
import '../routes/navRoutes.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () =>
              Navigator.pushReplacementNamed(context, NavRoutes.signIn),
          child: const Text('Get started'),
        ),
      ),
    );
  }
}
