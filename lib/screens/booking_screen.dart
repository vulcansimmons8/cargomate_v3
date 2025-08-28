import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/widgets.dart';
import 'map_picker_screen.dart'; // <-- ensure this exists as implemented earlier

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _pickupCtl = TextEditingController();
  final _dropCtl = TextEditingController();

  LatLng? _pickupPos;
  LatLng? _dropPos;
  String _vehicle = 'bike';
  bool _busy = false;

  @override
  void dispose() {
    _pickupCtl.dispose();
    _dropCtl.dispose();
    super.dispose();
  }

  Future<void> _pickOnMap({required bool isPickup}) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(mode: isPickup ? 'pickup' : 'drop'),
      ),
    );

    if (res is Map) {
      final address = (res['address'] ?? '').toString();
      final lat = (res['lat'] as num?)?.toDouble();
      final lng = (res['lng'] as num?)?.toDouble();

      if (address.isNotEmpty && lat != null && lng != null) {
        setState(() {
          if (isPickup) {
            _pickupCtl.text = address;
            _pickupPos = LatLng(lat, lng);
          } else {
            _dropCtl.text = address;
            _dropPos = LatLng(lat, lng);
          }
        });
      }
    }
  }

  Future<void> _book() async {
    if (_pickupPos == null || _dropPos == null) {
      AppSnack.show(context, 'Please choose pickup and drop locations');
      return;
    }

    setState(() => _busy = true);
    try {
      final supa = Supabase.instance.client;
      final user = supa.auth.currentUser;
      if (user == null) throw 'Not signed in';

      final distanceKm =
          Geolocator.distanceBetween(
            _pickupPos!.latitude,
            _pickupPos!.longitude,
            _dropPos!.latitude,
            _dropPos!.longitude,
          ) /
          1000.0;

      final baseRate = (_vehicle == 'truck')
          ? 15.0
          : (_vehicle == 'van')
          ? 8.0
          : 5.0;
      final price = (distanceKm * baseRate).round();

      await supa.from('deliveries').insert({
        'sender_id': user.id,
        'pickup_lat': _pickupPos!.latitude,
        'pickup_lng': _pickupPos!.longitude,
        'drop_lat': _dropPos!.latitude,
        'drop_lng': _dropPos!.longitude,
        'pickup_address': _pickupCtl.text.trim(),
        'drop_address': _dropCtl.text.trim(),
        'vehicle_type': _vehicle,
        'price': price,
        // 'status': 'pending', // optional default handled by DB
      });

      if (!mounted) return;
      AppSnack.show(context, 'Delivery booked: GHS $price');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        AppSnack.show(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Book a Delivery',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _pickupCtl,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Pickup',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.location_on_outlined),
                  onPressed: () => _pickOnMap(isPickup: true),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dropCtl,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Drop',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.location_searching),
                  onPressed: () => _pickOnMap(isPickup: false),
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _vehicle,
              decoration: const InputDecoration(labelText: 'Vehicle'),
              items: const [
                DropdownMenuItem(value: 'bike', child: Text('Bike')),
                DropdownMenuItem(value: 'van', child: Text('Van')),
                DropdownMenuItem(value: 'truck', child: Text('Truck')),
              ],
              onChanged: (v) => setState(() => _vehicle = v ?? 'bike'),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Book delivery',
                onPressed: _busy ? () {} : _book,
                loading: _busy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
