import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart'; // <-- keep imports at top
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _pickup = TextEditingController();
  final _drop = TextEditingController();
  String _vehicle = 'bike';
  bool _busy = false;

  @override
  void dispose() {
    _pickup.dispose();
    _drop.dispose();
    super.dispose();
  }

  Future<void> _pickLocations() async {
    // Opens LocationSelectionScreen and waits for result: {'pickup': ..., 'drop': ...}
    final res = await Navigator.pushNamed(context, '/locationSelection');
    if (res is Map) {
      setState(() {
        _pickup.text = (res['pickup'] ?? '').toString();
        _drop.text = (res['drop'] ?? '').toString();
      });
    }
  }

  Future<void> _book() async {
    setState(() => _busy = true);
    try {
      final pickupText = _pickup.text.trim();
      final dropText = _drop.text.trim();
      if (pickupText.isEmpty || dropText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please choose pickup and drop locations'),
          ),
        );
        setState(() => _busy = false);
        return;
      }

      final supa = Supabase.instance.client;
      final user = supa.auth.currentUser;
      if (user == null) throw 'Not signed in';

      // 1) Geocode addresses → lat/lng
      final pickupResults = await locationFromAddress(pickupText);
      if (pickupResults.isEmpty) throw 'Could not find pickup location';
      final dropResults = await locationFromAddress(dropText);
      if (dropResults.isEmpty) throw 'Could not find drop location';

      final pickupLat = pickupResults.first.latitude;
      final pickupLng = pickupResults.first.longitude;
      final dropLat = dropResults.first.latitude;
      final dropLng = dropResults.first.longitude;

      // 2) Distance (km) + simple pricing
      final distanceKm =
          Geolocator.distanceBetween(pickupLat, pickupLng, dropLat, dropLng) /
          1000.0;

      final baseRate = (_vehicle == 'truck')
          ? 15.0
          : (_vehicle == 'van')
          ? 8.0
          : 5.0;
      final price = (distanceKm * baseRate).round();

      // 3) Insert
      await supa.from('deliveries').insert({
        'sender_id': user.id,
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'drop_lat': dropLat,
        'drop_lng': dropLng,
        'pickup_address': pickupText,
        'drop_address': dropText,
        'vehicle_type': _vehicle,
        'price': price,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delivery booked: GHS $price')));
      Navigator.pop(context); // back to Home
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book a delivery')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _pickup,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Pickup',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.location_on_outlined),
                  onPressed: _pickLocations,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _drop,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Drop',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.location_searching),
                  onPressed: _pickLocations,
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              value: _vehicle,
              items: const [
                DropdownMenuItem(value: 'bike', child: Text('Bike')),
                DropdownMenuItem(value: 'van', child: Text('Van')),
                DropdownMenuItem(value: 'truck', child: Text('Truck')),
              ],
              onChanged: (v) => setState(() => _vehicle = v!),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _book,
              child: _busy
                  ? const CircularProgressIndicator()
                  : const Text('Book delivery'),
            ),
          ],
        ),
      ),
    );
  }
}
