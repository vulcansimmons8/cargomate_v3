import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerScreen extends StatefulWidget {
  /// mode is just a label to help caller know if this is for 'pickup' or 'drop'
  final String mode; // e.g., 'pickup' or 'drop'
  final LatLng? initialCenter;

  const MapPickerScreen({super.key, required this.mode, this.initialCenter});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _selected;
  String? _address;
  bool _busy = false;
  bool _mapReady = false;

  // Accra as a sensible default center
  static const LatLng _accra = LatLng(5.6037, -0.1870);

  @override
  void initState() {
    super.initState();
    // After map is created we try to move to user's location (permission may prompt)
  }

  Future<void> _moveToUser() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) return;
      if (permission == LocationPermission.denied) {
        final again = await Geolocator.requestPermission();
        if (again == LocationPermission.denied ||
            again == LocationPermission.deniedForever)
          return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final c = await _controller.future;
      await c.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 14),
      );
    } catch (_) {
      // Ignore if user denies permission or location fails
    }
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    setState(() {
      _busy = true;
      _address = null;
    });
    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[
          if ((p.street ?? '').trim().isNotEmpty) p.street!,
          if ((p.locality ?? '').trim().isNotEmpty) p.locality!,
          if ((p.subAdministrativeArea ?? '').trim().isNotEmpty)
            p.subAdministrativeArea!,
          if ((p.administrativeArea ?? '').trim().isNotEmpty)
            p.administrativeArea!,
          if ((p.country ?? '').trim().isNotEmpty) p.country!,
        ];
        setState(() => _address = parts.join(', '));
      } else {
        setState(() => _address = 'Unknown place');
      }
    } catch (_) {
      setState(() => _address = 'Unknown place');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onTap(LatLng latLng) {
    setState(() => _selected = latLng);
    _reverseGeocode(latLng);
  }

  void _confirm() {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tap on the map to choose a location')),
      );
      return;
    }
    Navigator.pop(context, {
      'lat': _selected!.latitude,
      'lng': _selected!.longitude,
      'address': _address ?? '',
      'mode': widget.mode,
    });
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.initialCenter ?? _accra;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pick ${widget.mode == 'pickup' ? 'Pickup' : 'Drop'}'),
        actions: [
          IconButton(
            tooltip: 'Use this location',
            icon: const Icon(Icons.check),
            onPressed: _confirm,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: start, zoom: 12),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (c) async {
              _controller.complete(c);
              setState(() => _mapReady = true);
              // Try centering on user a moment after map is ready (does nothing if denied)
              // ignore: use_build_context_synchronously
              await _moveToUser();
            },
            onTap: _onTap,
            markers: {
              if (_selected != null)
                Marker(
                  markerId: const MarkerId('selected'),
                  position: _selected!,
                ),
            },
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.place),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selected == null
                            ? (_mapReady
                                  ? 'Tap anywhere to select a location'
                                  : 'Loading map…')
                            : (_busy
                                  ? 'Resolving address…'
                                  : (_address?.isNotEmpty == true
                                        ? _address!
                                        : 'Selected location')),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _busy ? null : _confirm,
                      child: const Text('Use'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
