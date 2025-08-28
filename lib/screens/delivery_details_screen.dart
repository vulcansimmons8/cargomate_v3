import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/widgets.dart';

class DeliveryDetailsScreen extends StatefulWidget {
  /// Pass the whole delivery map via Navigator arguments.
  final Map<String, dynamic> delivery;

  const DeliveryDetailsScreen({super.key, required this.delivery});

  @override
  State<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends State<DeliveryDetailsScreen> {
  final Completer<GoogleMapController> _mapCtl = Completer();
  Map<String, dynamic> get d => widget.delivery;

  LatLng? get _pickup => (d['pickup_lat'] != null && d['pickup_lng'] != null)
      ? LatLng(
          (d['pickup_lat'] as num).toDouble(),
          (d['pickup_lng'] as num).toDouble(),
        )
      : null;

  LatLng? get _drop => (d['drop_lat'] != null && d['drop_lng'] != null)
      ? LatLng(
          (d['drop_lat'] as num).toDouble(),
          (d['drop_lng'] as num).toDouble(),
        )
      : null;

  Future<void> _fitBounds() async {
    if (_pickup == null && _drop == null) return;
    final ctl = await _mapCtl.future;

    if (_pickup != null && _drop != null) {
      final sw = LatLng(
        (_pickup!.latitude <= _drop!.latitude)
            ? _pickup!.latitude
            : _drop!.latitude,
        (_pickup!.longitude <= _drop!.longitude)
            ? _pickup!.longitude
            : _drop!.longitude,
      );
      final ne = LatLng(
        (_pickup!.latitude >= _drop!.latitude)
            ? _pickup!.latitude
            : _drop!.latitude,
        (_pickup!.longitude >= _drop!.longitude)
            ? _pickup!.longitude
            : _drop!.longitude,
      );
      final bounds = LatLngBounds(southwest: sw, northeast: ne);
      await ctl.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
    } else {
      final one = _pickup ?? _drop!;
      await ctl.animateCamera(CameraUpdate.newLatLngZoom(one, 14));
    }
  }

  @override
  Widget build(BuildContext context) {
    final supa = Supabase.instance.client;
    final user = supa.auth.currentUser;

    final pickupAddr = (d['pickup_address'] ?? 'Unknown').toString();
    final dropAddr = (d['drop_address'] ?? 'Unknown').toString();
    final price = (d['price'] ?? '').toString();
    final vehicle = (d['vehicle_type'] ?? 'vehicle').toString();
    final status = (d['status'] ?? 'pending').toString();
    final created = (d['created_at'] ?? '').toString();

    final bool isDriverForThis =
        d['driver_id'] != null && user != null && d['driver_id'] == user.id;

    // Build markers set
    final markers = <Marker>{
      if (_pickup != null)
        const Marker(
          markerId: MarkerId('pickup'),
          position: LatLng(0, 0), // will be replaced below
        ).copyWith(positionParam: _pickup),
      if (_drop != null)
        const Marker(
          markerId: MarkerId('drop'),
          position: LatLng(0, 0),
        ).copyWith(positionParam: _drop),
    };

    return Scaffold(
      appBar: const CustomAppBar(title: 'Delivery Details'),
      body: LoadingOverlay(
        show: false,
        child: Column(
          children: [
            // Map area
            SizedBox(
              height: 280,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target:
                        _pickup ??
                        _drop ??
                        const LatLng(5.6037, -0.1870), // Accra fallback
                    zoom: 12,
                  ),
                  onMapCreated: (c) async {
                    _mapCtl.complete(c);
                    await Future.delayed(const Duration(milliseconds: 250));
                    await _fitBounds();
                  },
                  markers: markers,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                ),
              ),
            ),

            const Gap.h(12),

            // Info card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'GHS $price',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          StatusChip(status: status),
                        ],
                      ),
                      const Gap.h(8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.place, size: 18),
                          const Gap.w(6),
                          Expanded(child: Text('Pickup: $pickupAddr')),
                        ],
                      ),
                      const Gap.h(6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.flag, size: 18),
                          const Gap.w(6),
                          Expanded(child: Text('Drop:   $dropAddr')),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.local_shipping_outlined, size: 18),
                          const Gap.w(6),
                          Text('Vehicle: $vehicle'),
                        ],
                      ),
                      const Gap.h(6),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 18),
                          const Gap.w(6),
                          Text('Created: $created'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  if (isDriverForThis) ...[
                    Expanded(
                      child: SecondaryButton(
                        label: 'Start (Enroute)',
                        onPressed: () async {
                          await supa
                              .from('deliveries')
                              .update({'status': 'enroute'})
                              .eq('id', d['id']);
                          if (!mounted) return;
                          AppSnack.show(context, 'Status: enroute');
                          setState(() => d['status'] = 'enroute');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Complete',
                        onPressed: () async {
                          await supa
                              .from('deliveries')
                              .update({'status': 'delivered'})
                              .eq('id', d['id']);
                          if (!mounted) return;
                          AppSnack.show(context, 'Delivered!');
                          setState(() => d['status'] = 'delivered');
                        },
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: SecondaryButton(
                        label: 'Close',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
