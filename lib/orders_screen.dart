import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final r = await sb
        .from('orders')
        .select('*, order_items(product_name, qty, unit_price_minor)')
        .eq('user_id', sb.auth.currentUser!.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(r);
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'delivered':
        return Colors.greenAccent;
      case 'cancelled':
      case 'refunded':
        return Colors.redAccent;
      case 'shipped':
        return Colors.lightBlueAccent;
      default:
        return kOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _future = _load());
        await _future;
      },
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text(errText(snap.error!)));
          final orders = snap.data ?? [];
          if (orders.isEmpty) {
            return ListView(children: [
              const SizedBox(height: 120),
              Center(child: Text(app.t('orders'))),
            ]);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (_, i) {
              final o = orders[i];
              final cur = o['currency'] as String;
              final items = List<Map<String, dynamic>>.from(o['order_items'] ?? []);
              final status = o['status'] as String;
              final tracking = o['tracking_number'] as String?;
              return Card(
                color: kDark,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('#${(o['id'] as String).substring(0, 8)}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(status.toUpperCase(),
                              style: TextStyle(
                                  color: _statusColor(status),
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      for (final it in items)
                        Text('${it['qty']} × ${it['product_name']}',
                            style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 6),
                      Text(
                          '${app.t('total')}: ${money((o['total_minor'] as num).toInt(), cur)}'
                          '  •  ${(o['payment_method'] as String).toUpperCase()}'
                          '  •  ${o['payment_status']}',
                          style: const TextStyle(color: kOrange)),
                      if (tracking != null && tracking.isNotEmpty)
                        Text('Tracking: $tracking'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
