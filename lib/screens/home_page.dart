import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../routes/navRoutes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  NavRoutes.signIn,
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, NavRoutes.book),
              child: const Text('New Delivery'),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () =>
                  Navigator.pushNamed(context, NavRoutes.myDeliveries),
              child: const Text('My Deliveries'),
            ),
          ],
        ),
      ),
    );
  }
}
