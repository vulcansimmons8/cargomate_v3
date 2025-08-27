import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyDeliveriesScreen extends StatelessWidget {
  const MyDeliveriesScreen({super.key});

  Future<List<Map<String, dynamic>>> _fetchDeliveries(
    SupabaseClient supa,
  ) async {
    final user = supa.auth.currentUser;
    if (user == null) return [];
    final data = await supa
        .from('deliveries')
        .select()
        // RLS already limits to your rows; keeping this is optional:
        .eq('sender_id', user.id)
        .order('created_at', ascending: false);

    // Cast the dynamic list to the right shape
    return List<Map<String, dynamic>>.from(data as List);
  }

  String _fmtDate(dynamic iso) {
    try {
      final dt = DateTime.parse(iso.toString()).toLocal();
      // simple readable format without adding a package
      final y = dt.year,
          m = dt.month.toString().padLeft(2, '0'),
          d = dt.day.toString().padLeft(2, '0');
      final hh = dt.hour.toString().padLeft(2, '0'),
          mm = dt.minute.toString().padLeft(2, '0');
      return "$y-$m-$d $hh:$mm";
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final supa = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(title: const Text('My Deliveries')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchDeliveries(supa),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final data = snap.data ?? const [];
          if (data.isEmpty) {
            return const Center(child: Text('No deliveries yet.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Trigger a rebuild by popping and pushing this route (simple trick)
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                ModalRoute.of(context)!.settings.name!,
              );
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: data.length,
              itemBuilder: (_, i) {
                final d = data[i];
                final vehicle = (d['vehicle_type'] ?? 'vehicle').toString();
                final price = (d['price'] ?? '').toString();
                final pickup = (d['pickup_address'] ?? 'Unknown').toString();
                final drop = (d['drop_address'] ?? 'Unknown').toString();
                final status = (d['status'] ?? '').toString();
                final created = _fmtDate(d['created_at']);

                return ListTile(
                  leading: const Icon(Icons.local_shipping),
                  title: Text('$vehicle — GHS $price'),
                  subtitle: Text('$pickup → $drop\n$created'),
                  isThreeLine: true,
                  trailing: Text(status),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
