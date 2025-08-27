import 'package:flutter/material.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final _pickup = TextEditingController();
  final _drop = TextEditingController();

  @override
  void dispose() {
    _pickup.dispose();
    _drop.dispose();
    super.dispose();
  }

  void _useLocations() {
    // Return selected locations to the caller (Navigator.pop with a result map)
    Navigator.pop(context, {
      'pickup': _pickup.text.trim(),
      'drop': _drop.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Locations')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _pickup,
              decoration: const InputDecoration(
                labelText: 'Pickup (address or landmark)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _drop,
              decoration: const InputDecoration(
                labelText: 'Drop (address or landmark)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _useLocations,
              child: const Text('Use these locations'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // TODO: In Sprint 3, push a Google Map selector here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Map picker coming soon…')),
                );
              },
              child: const Text('Pick from map (coming soon)'),
            ),
          ],
        ),
      ),
    );
  }
}
