import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../routes/navRoutes.dart';
import '../widgets/widgets.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String phoneNumber;
  const ProfileSetupScreen({super.key, required this.phoneNumber});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  String _role = 'customer'; // default
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _phoneCtl.text = widget.phoneNumber;
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _phoneCtl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final supa = Supabase.instance.client;
    final user = supa.auth.currentUser;

    if (user == null) {
      if (!mounted) return;
      AppSnack.show(context, "No signed-in user.");
      setState(() => _loading = false);
      return;
    }

    try {
      await supa.from('profiles').upsert({
        'id': user.id, // uuid PK = user id
        'full_name': _nameCtl.text.trim(),
        'phone_number': _phoneCtl.text.trim(),
        'role': _role,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        NavRoutes.homePage,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnack.show(context, "Error saving profile: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Setup Profile'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtl,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const Gap.h(12),
              TextFormField(
                controller: _phoneCtl,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const Gap.h(12),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'customer', child: Text('Customer')),
                  DropdownMenuItem(value: 'driver', child: Text('Driver')),
                ],
                onChanged: (val) => setState(() => _role = val ?? 'customer'),
              ),
              const Gap.h(24),
              PrimaryButton(
                label: 'Save & Continue',
                onPressed: _saveProfile,
                loading: _loading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
