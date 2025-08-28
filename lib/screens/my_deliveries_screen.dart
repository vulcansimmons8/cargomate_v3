import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/widgets.dart';
import '../routes/navRoutes.dart';

class MyDeliveriesScreen extends StatelessWidget {
  const MyDeliveriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supa = Supabase.instance.client;

    return AppScaffold(
      title: 'My Deliveries',
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supa
            .from('deliveries')
            .select()
            .order('created_at', ascending: false),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ErrorPlaceholder(
              message: 'Error: ${snap.error}',
              onRetry: () {
                // cheap refresh
                (context as Element).reassemble();
              },
            );
          }

          final data = snap.data ?? [];
          if (data.isEmpty) {
            return const EmptyPlaceholder(
              title: 'No deliveries yet',
              message: 'Book your first delivery to see it here.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // trigger a rebuild; for proper refresh, move to a StatefulWidget and refetch
              (context as Element).reassemble();
              await Future.delayed(const Duration(milliseconds: 250));
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: data.length,
              itemBuilder: (_, i) {
                final d = data[i];
                return DeliveryTile(
                  delivery: d,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      NavRoutes.deliveryDetails,
                      arguments: d,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
