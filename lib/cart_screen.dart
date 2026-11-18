import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (app.cart.isEmpty) {
      return Center(child: Text(app.t('cartEmpty')));
    }
    final cur = app.cartCurrency;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final l in app.cart.values)
                Card(
                  color: kDark,
                  child: ListTile(
                    title: Text(app.pname(l.product)),
                    subtitle: Text(
                        '${money(l.product.priceMinor, cur)}  •  ${l.product.sellerName}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => app.changeQty(l.product.id, -1),
                        ),
                        Text('${l.qty}'),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => app.changeQty(l.product.id, 1),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(app.t('subtotal')),
                  Text(money(app.cartSubtotal, cur),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: kOrange)),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                ),
                child: Text(app.t('checkout')),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  List<Map<String, dynamic>> _addresses = [];
  String? _addressId;
  String _method = 'cod';
  final _coupon = TextEditingController();
  int? _shipping;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final app = context.read<AppState>();
    final r = await sb
        .from('addresses')
        .select()
        .eq('country', app.country == 'BD' ? 'BD' : 'US');
    if (!mounted) return;
    setState(() {
      _addresses = List<Map<String, dynamic>>.from(r);
      if (_addresses.isNotEmpty) {
        _addressId ??= _addresses.first['id'] as String;
      }
    });
    _loadShipping();
  }

  Future<void> _loadShipping() async {
    final app = context.read<AppState>();
    final a = _addresses.where((x) => x['id'] == _addressId);
    if (a.isEmpty) return;
    final addr = a.first;
    final zone = addr['country'] == 'US'
        ? 'domestic'
        : (addr['is_dhaka'] == true ? 'dhaka' : 'outside_dhaka');
    final r = await sb
        .from('shipping_rates')
        .select('cost_minor')
        .eq('country', addr['country'] as String)
        .eq('zone', zone)
        .eq('currency', app.cartCurrency);
    final list = List<Map<String, dynamic>>.from(r);
    if (mounted) {
      setState(() => _shipping =
          list.isEmpty ? null : (list.first['cost_minor'] as num).toInt());
    }
  }

  Future<void> _addAddress() async {
    final app = context.read<AppState>();
    final name = TextEditingController();
    final phone = TextEditingController();
    final line1 = TextEditingController();
    final city = TextEditingController();
    final state = TextEditingController();
    final zip = TextEditingController();
    bool dhaka = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(app.t('address')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: name,
                    decoration: InputDecoration(labelText: app.t('name'))),
                const SizedBox(height: 8),
                TextField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone')),
                const SizedBox(height: 8),
                TextField(
                    controller: line1,
                    decoration: const InputDecoration(labelText: 'Address')),
                const SizedBox(height: 8),
                TextField(
                    controller: city,
                    decoration: const InputDecoration(labelText: 'City')),
                const SizedBox(height: 8),
                TextField(
                    controller: state,
                    decoration: InputDecoration(
                        labelText:
                            app.country == 'BD' ? 'District' : 'State')),
                const SizedBox(height: 8),
                TextField(
                    controller: zip,
                    decoration: const InputDecoration(labelText: 'Postal code')),
                if (app.country == 'BD')
                  SwitchListTile(
                    title: const Text('Inside Dhaka'),
                    value: dhaka,
                    onChanged: (v) => setD(() => dhaka = v),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(app.t('cancel'))),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(app.t('save'))),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (name.text.trim().isEmpty ||
        phone.text.trim().isEmpty ||
        line1.text.trim().isEmpty ||
        city.text.trim().isEmpty) {
      if (mounted) toast(context, 'Name, phone, address and city are required.');
      return;
    }
    try {
      final row = await sb.from('addresses').insert({
        'user_id': sb.auth.currentUser!.id,
        'full_name': name.text.trim(),
        'phone': phone.text.trim(),
        'country': app.country,
        'line1': line1.text.trim(),
        'city': city.text.trim(),
        'state_or_district': state.text.trim(),
        'postal_code': zip.text.trim(),
        'is_dhaka': app.country == 'BD' && dhaka,
      }).select().single();
      _addressId = row['id'] as String;
      await _loadAddresses();
    } catch (e) {
      if (mounted) toast(context, errText(e));
    }
  }

  Future<void> _place() async {
    final app = context.read<AppState>();
    if (_addressId == null) {
      toast(context, app.t('address'));
      return;
    }
    setState(() => _busy = true);
    try {
      final items = [
        for (final l in app.cart.values)
          {'product_id': l.product.id, 'qty': l.qty}
      ];
      await sb.rpc('place_order', params: {
        'p_items': items,
        'p_address_id': _addressId,
        'p_payment_method': _method,
        'p_coupon': _coupon.text.trim().isEmpty ? null : _coupon.text.trim(),
      });
      app.clearCart();
      if (!mounted) return;
      toast(context, app.t('orderPlaced'));
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) toast(context, errText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cur = app.cartCurrency;
    // Payment methods: only COD is live. Others need real merchant accounts.
    final methods = app.country == 'BD'
        ? const ['cod', 'bkash', 'nagad', 'rocket']
        : const ['stripe', 'paypal', 'card'];
    final labels = {
      'cod': 'Cash on Delivery',
      'bkash': 'bKash',
      'nagad': 'Nagad',
      'rocket': 'Rocket',
      'stripe': 'Stripe',
      'paypal': 'PayPal',
      'card': 'Credit / Debit card',
    };
    final liveMethods = {'cod'};
    final subtotal = app.cartSubtotal;

    return Scaffold(
      appBar: AppBar(title: Text(app.t('checkout'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(app.t('address'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          for (final a in _addresses)
            RadioListTile<String>(
              value: a['id'] as String,
              groupValue: _addressId,
              onChanged: (v) {
                setState(() => _addressId = v);
                _loadShipping();
              },
              title: Text('${a['full_name']}  ${a['phone']}'),
              subtitle: Text('${a['line1']}, ${a['city']}'),
            ),
          TextButton.icon(
            onPressed: _addAddress,
            icon: const Icon(Icons.add),
            label: const Text('Add address'),
          ),
          const Divider(),
          Text(app.t('payment'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          for (final m in methods)
            RadioListTile<String>(
              value: m,
              groupValue: _method,
              onChanged: liveMethods.contains(m)
                  ? (v) => setState(() => _method = v!)
                  : null,
              title: Text(labels[m]!),
              subtitle:
                  liveMethods.contains(m) ? null : Text(app.t('comingSoon')),
            ),
          if (app.country != 'BD')
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'USA checkout is disabled until a Stripe/PayPal merchant '
                'account is connected. No fake payments are accepted.',
                style: TextStyle(color: Colors.amber),
              ),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _coupon,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(labelText: app.t('coupon')),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(app.t('subtotal')), Text(money(subtotal, cur))],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(app.t('shipping')),
              Text(_shipping == null ? '—' : money(_shipping!, cur)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(app.t('total'),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  money(subtotal + (_shipping ?? 0), cur),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: kOrange)),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed:
                (_busy ||
                        !methods.contains(_method) ||
                        !liveMethods.contains(_method) ||
                        app.cart.isEmpty)
                    ? null
                    : _place,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(app.t('placeOrder')),
          ),
        ],
      ),
    );
  }
}
