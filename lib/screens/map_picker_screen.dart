import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerScreen extends StatefulWidget {
  final String mode; // e.g., 'pickup' or 'drop'
  final LatLng? initialCenter;

  const MapPickerScreen({super.key, required this.mode, this.initialCenter});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  final Duration _debounceDuration = const Duration(milliseconds: 500);
  final TextEditingController _searchController = TextEditingController();

  LatLng? _selected;
  String? _address;
  bool _busy = false;
  bool _mapReady = false;

  Timer? _debounce;

  static const LatLng _accra = LatLng(5.6037, -0.1870);

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _moveToUser() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      final c = await _controller.future;
      await c.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 14),
      );
    } catch (e) {
      debugPrint('Error moving to user location: $e');
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
        final parts =
            <String?>[
                  p.street,
                  p.locality,
                  p.subAdministrativeArea,
                  p.administrativeArea,
                  p.country,
                ]
                .where((e) => e != null && e!.trim().isNotEmpty)
                .cast<String>()
                .toList();

        if (mounted) setState(() => _address = parts.join(', '));
      } else {
        if (mounted) setState(() => _address = 'Unknown place');
      }
    } catch (e) {
      if (mounted) setState(() => _address = 'Unknown place');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => _busy = true);

    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final newLatLng = LatLng(loc.latitude, loc.longitude);
        final c = await _controller.future;
        await c.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 14));

        setState(() => _selected = newLatLng);
        await _reverseGeocode(newLatLng);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No results found')));
      }
    } catch (e) {
      debugPrint('Error searching address: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not find location')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onTap(LatLng latLng) {
    HapticFeedback.lightImpact();
    setState(() => _selected = latLng);

    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () => _reverseGeocode(latLng));
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
      'address': _address ?? 'Unnamed location',
      'mode': widget.mode,
    });
  }

  Future<void> _zoomIn() async {
    final c = await _controller.future;
    await c.animateCamera(CameraUpdate.zoomIn());
  }

  Future<void> _zoomOut() async {
    final c = await _controller.future;
    await c.animateCamera(CameraUpdate.zoomOut());
  }

  Widget _buildGoogleMap(LatLng start) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: start, zoom: 12),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      onMapCreated: (c) async {
        if (!_controller.isCompleted) {
          _controller.complete(c);
        }
        if (mounted) setState(() => _mapReady = true);

        await _moveToUser();
      },
      onTap: _onTap,
      markers: {
        if (_selected != null)
          Marker(markerId: const MarkerId('selected'), position: _selected!),
      },
    );
  }

  Widget _buildLocationCard() {
    String message;
    if (_selected == null) {
      message = _mapReady
          ? 'Tap anywhere to select a location'
          : 'Loading map…';
    } else if (_busy) {
      message = 'Resolving address…';
    } else {
      message = (_address?.isNotEmpty == true)
          ? _address!
          : 'Selected location';
    }

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.place, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _busy ? null : _confirm,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Use'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Positioned(
      right: 12,
      top: 100,
      child: Column(
        children: [
          _zoomButton(Icons.add, _zoomIn),
          const SizedBox(height: 8),
          _zoomButton(Icons.remove, _zoomOut),
        ],
      ),
    );
  }

  Widget _zoomButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 24),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    if (_mapReady) return const SizedBox.shrink();
    return const Center(child: CircularProgressIndicator());
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.initialCenter ?? _accra;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: _searchAddress,
          decoration: const InputDecoration(
            hintText: 'Search location...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: Colors.white,
        ),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => _searchAddress(_searchController.text),
          ),
          IconButton(
            tooltip: 'Use this location',
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _confirm,
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildGoogleMap(start),
          _buildZoomControls(),
          _buildLocationCard(),
          if (!_mapReady) _buildLoadingOverlay(),
        ],
      ),
    );
  }
}
