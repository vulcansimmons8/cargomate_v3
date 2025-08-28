import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../routes/navRoutes.dart';
import 'home_page.dart'; // customer home
import 'driver_home_page.dart'; // driver home

class HomeRouter extends StatefulWidget {
  const HomeRouter({super.key});

  @override
  State<HomeRouter> createState() => _HomeRouterState();
}

class _HomeRouterState extends State<HomeRouter> {
  bool _loading = true;
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final supa = Supabase.instance.client;
    final user = supa.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, NavRoutes.signIn);
      return;
    }

    try {
      final profile = await supa
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _role = profile?['role'] ?? 'customer';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _role = 'customer';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_role == 'driver') {
      return const DriverHomePage();
    } else {
      return const HomePage(); // default customer
    }
  }
}
