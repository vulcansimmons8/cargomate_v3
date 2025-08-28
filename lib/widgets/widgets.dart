import 'package:cargomate_v3/viewmodel/role_view_model.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../routes/navRoutes.dart';

/// ---------- Spacing helper ----------
class Gap extends StatelessWidget {
  final double h, w;
  const Gap({super.key, this.h = 0, this.w = 0});
  const Gap.h(this.h, {super.key}) : w = 0;
  const Gap.w(this.w, {super.key}) : h = 0;

  @override
  Widget build(BuildContext context) => SizedBox(height: h, width: w);
}

/// ---------- AppBar ----------
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  const CustomAppBar({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title), centerTitle: true, actions: actions);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// ---------- Buttons ----------
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool loading;
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool loading;
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}

/// ---------- Tiny map preview ----------
class MiniMap extends StatelessWidget {
  final double lat;
  final double lng;
  const MiniMap({super.key, required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    final pos = LatLng(lat, lng);
    return SizedBox(
      width: 100,
      height: 80,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: pos, zoom: 14),
          markers: {Marker(markerId: const MarkerId('m'), position: pos)},
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          scrollGesturesEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          zoomGesturesEnabled: false,
          liteModeEnabled: true, // Android-only
        ),
      ),
    );
  }
}

/// ---------- Status chip ----------
class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  Color _bg() {
    final s = status.toLowerCase();
    if (s.contains('done') || s.contains('delivered'))
      return Colors.green.withOpacity(.15);
    if (s.contains('route') || s.contains('enroute'))
      return Colors.blue.withOpacity(.15);
    if (s.contains('accept')) return Colors.orange.withOpacity(.15);
    return Colors.grey.withOpacity(.15);
  }

  Color _fg() {
    final s = status.toLowerCase();
    if (s.contains('done') || s.contains('delivered'))
      return Colors.green.shade800;
    if (s.contains('route') || s.contains('enroute'))
      return Colors.blue.shade800;
    if (s.contains('accept')) return Colors.orange.shade800;
    return Colors.grey.shade800;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _bg(),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: _fg(),
          fontSize: 12,
        ),
      ),
    );
  }
}

/// ---------- Delivery list tile ----------
class DeliveryTile extends StatelessWidget {
  final Map<String, dynamic> delivery;
  final VoidCallback? onTap;
  const DeliveryTile({super.key, required this.delivery, this.onTap});

  String _fmtDate(dynamic iso) {
    try {
      final dt = DateTime.parse(iso.toString()).toLocal();
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickup = (delivery['pickup_address'] ?? 'Unknown').toString();
    final drop = (delivery['drop_address'] ?? 'Unknown').toString();
    final price = delivery['price']?.toString() ?? '-';
    final vehicle = (delivery['vehicle_type'] ?? 'vehicle').toString();
    final status = (delivery['status'] ?? 'pending').toString();
    final created = _fmtDate(delivery['created_at']);

    final lat = (delivery['pickup_lat'] as num?)?.toDouble();
    final lng = (delivery['pickup_lng'] as num?)?.toDouble();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: (lat != null && lng != null)
            ? MiniMap(lat: lat, lng: lng)
            : const Icon(Icons.local_shipping),
        title: Text(
          '$vehicle — GHS $price',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('$pickup → $drop\n$created'),
        isThreeLine: true,
        trailing: StatusChip(status: status),
      ),
    );
  }
}

/// ---------- Empty / Error / Loading ----------
class EmptyPlaceholder extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? action;
  const EmptyPlaceholder({
    super.key,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 48),
            const Gap.h(12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            if (message != null) ...[
              const Gap.h(6),
              Text(message!, textAlign: TextAlign.center),
            ],
            if (action != null) ...[const Gap.h(12), action!],
          ],
        ),
      ),
    );
  }
}

class ErrorPlaceholder extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorPlaceholder({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const Gap.h(12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const Gap.h(12),
              SecondaryButton(label: 'Retry', onPressed: onRetry!),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool show;
  final Widget child;
  const LoadingOverlay({super.key, required this.show, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (show)
          Container(
            color: Colors.black.withOpacity(.15),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

/// ---------- Snack / Dialog ----------
class AppSnack {
  static void show(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return result ?? false;
}

// ==============================
// Logout helper
// ==============================
Future<void> _logout(BuildContext context) async {
  final supa = Supabase.instance.client;
  final roleVM = context.read<RoleViewModel>();

  await supa.auth.signOut();
  roleVM.clearRole();

  Navigator.pushNamedAndRemoveUntil(
    context,
    NavRoutes.signIn,
    (route) => false,
  );
}

// ==============================
// Customer Drawer
// ==============================
class CustomerDrawer extends StatelessWidget {
  const CustomerDrawer({super.key});

  void _go(BuildContext context, String route) {
    Navigator.pop(context);
    if (ModalRoute.of(context)?.settings.name == route) return;
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.local_shipping, size: 36),
                  SizedBox(height: 8),
                  Text(
                    'CargoMate',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text('Customer'),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () => _go(context, NavRoutes.homePage),
            ),
            ListTile(
              leading: const Icon(Icons.add_location_alt_outlined),
              title: const Text('New Delivery'),
              onTap: () => _go(context, NavRoutes.book),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt_outlined),
              title: const Text('My Deliveries'),
              onTap: () => _go(context, NavRoutes.myDeliveries),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                final confirm = await showConfirmDialog(
                  context,
                  title: 'Logout',
                  message: 'Are you sure you want to log out?',
                );
                if (confirm) {
                  _logout(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================
// Driver Drawer
// ==============================
class DriverDrawer extends StatelessWidget {
  const DriverDrawer({super.key});

  void _go(BuildContext context, String route) {
    Navigator.pop(context);
    if (ModalRoute.of(context)?.settings.name == route) return;
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.directions_car_filled_outlined, size: 36),
                  SizedBox(height: 8),
                  Text(
                    'CargoMate',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text('Driver'),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Driver Home'),
              onTap: () => _go(context, NavRoutes.driverHome),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                final confirm = await showConfirmDialog(
                  context,
                  title: 'Logout',
                  message: 'Are you sure you want to log out?',
                );
                if (confirm) {
                  _logout(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final roleVM = context.watch<RoleViewModel>();

    // Check the role and assign the correct drawer
    final drawer = roleVM.role == 'customer'
        ? const CustomerDrawer()
        : const DriverDrawer();

    return Scaffold(
      appBar: CustomAppBar(title: title, actions: actions),
      drawer: drawer,
      body: body,
    );
  }
}
