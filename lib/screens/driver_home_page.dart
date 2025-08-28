import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/widgets.dart';
import '../routes/navRoutes.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  bool _online = false;
  bool _busy = false;
  StreamSubscription<Position>? _posSub;

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  Future<void> _toggleOnline(bool value) async {
    final supa = Supabase.instance.client;
    final user = supa.auth.currentUser;
    if (user == null) {
      AppSnack.show(context, 'Not signed in');
      return;
    }

    if (value) {
      // Going online
      final granted = await _ensureLocationPermission();
      if (!granted) {
        AppSnack.show(context, 'Location permission required');
        return;
      }
      setState(() => _online = true);

      _posSub?.cancel();
      _posSub =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          ).listen((pos) async {
            try {
              await supa.from('driver_locations').upsert({
                'driver_id': user.id,
                'lat': pos.latitude,
                'lng': pos.longitude,
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              }, onConflict: 'driver_id');
            } catch (_) {
              // ignore transient errors
            }
          });
    } else {
      // Going offline
      await _posSub?.cancel();
      _posSub = null;
      setState(() => _online = false);
    }
  }

  Future<bool> _ensureLocationPermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  Future<void> _acceptJob(Map<String, dynamic> d) async {
    final supa = Supabase.instance.client;
    final user = supa.auth.currentUser;
    if (user == null) return;

    setState(() => _busy = true);
    try {
      await supa
          .from('deliveries')
          .update({'driver_id': user.id, 'status': 'accepted'})
          .eq('id', d['id']);

      if (!mounted) return;
      AppSnack.show(context, 'Job accepted');

      // Optionally navigate to details
      final withDriver = {...d, 'driver_id': user.id, 'status': 'accepted'};
      Navigator.pushNamed(
        context,
        NavRoutes.deliveryDetails,
        arguments: withDriver,
      );
    } catch (e) {
      if (mounted) AppSnack.show(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final supa = Supabase.instance.client;

    return AppScaffold(
      title: 'Driver Home',
      body: LoadingOverlay(
        show: _busy,
        child: Column(
          children: [
            // Online switch
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.power_settings_new),
                  const SizedBox(width: 8),
                  const Text('Go Online'),
                  const Spacer(),
                  Switch(value: _online, onChanged: _toggleOnline),
                ],
              ),
            ),
            const Divider(),

            // Available jobs: status=pending AND driver_id IS NULL
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: supa
                    .from('deliveries')
                    .select()
                    .isFilter('driver_id', null) // ✅ IS NULL correctly
                    .eq('status', 'pending')
                    .order('created_at', ascending: false),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return ErrorPlaceholder(message: 'Error: ${snap.error}');
                  }

                  final data = snap.data ?? [];
                  if (data.isEmpty) {
                    return const EmptyPlaceholder(
                      title: 'No available jobs',
                      message:
                          'When customers book new deliveries, they will appear here.',
                    );
                  }

                  return ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (_, i) {
                      final d = data[i];
                      return DeliveryTile(
                        delivery: d,
                        onTap: () => _acceptJob(d),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
