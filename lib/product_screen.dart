import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'cart_screen.dart';
import 'core.dart';

class ProductScreen extends StatefulWidget {
  final Product product;
  const ProductScreen({super.key, required this.product});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  bool _wished = false;
  late Future<List<Map<String, dynamic>>> _reviews;

  @override
  void initState() {
    super.initState();
    _reviews = _loadReviews();
    _loadWish();
  }

  Future<List<Map<String, dynamic>>> _loadReviews() async {
    final r = await sb
        .from('reviews')
        .select('rating, comment, created_at')
        .eq('product_id', widget.product.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(r);
  }

  Future<void> _loadWish() async {
    final uid = sb.auth.currentUser?.id;
    if (uid == null) return;
    final r = await sb
        .from('wishlist')
        .select()
        .eq('user_id', uid)
        .eq('product_id', widget.product.id);
    if (mounted) setState(() => _wished = (r as List).isNotEmpty);
  }

  Future<void> _toggleWish() async {
    final uid = sb.auth.currentUser!.id;
    try {
      if (_wished) {
        await sb
            .from('wishlist')
            .delete()
            .eq('user_id', uid)
            .eq('product_id', widget.product.id);
      } else {
        await sb
            .from('wishlist')
            .insert({'user_id': uid, 'product_id': widget.product.id});
      }
      if (mounted) setState(() => _wished = !_wished);
    } catch (e) {
      if (mounted) toast(context, errText(e));
    }
  }

  Future<void> _writeReview() async {
    final app = context.read<AppState>();
    int rating = 5;
    final comment = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(app.t('writeReview')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      icon: Icon(i <= rating ? Icons.star : Icons.star_border,
                          color: kOrange),
                      onPressed: () => setD(() => rating = i),
                    ),
                ],
              ),
              TextField(controller: comment, maxLines: 3),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(app.t('cancel'))),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(app.t('send'))),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await sb.from('reviews').insert({
        'product_id': widget.product.id,
        'user_id': sb.auth.currentUser!.id,
        'rating': rating,
        'comment': comment.text.trim(),
      });
      if (mounted) setState(() => _reviews = _loadReviews());
    } catch (e) {
      if (mounted) {
        toast(context, errText(e).contains('duplicate')
            ? 'You already reviewed this product.'
            : errText(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final p = widget.product;
    return Scaffold(
      appBar: AppBar(
        title: Text(app.pname(p), overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(_wished ? Icons.favorite : Icons.favorite_border,
                color: kOrange),
            onPressed: _toggleWish,
          ),
        ],
      ),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 1.3,
            child: Container(
              color: kGrey,
              child: p.images.isNotEmpty
                  ? Image.network(p.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.settings,
                          size: 72, color: Colors.white24))
                  : const Icon(Icons.settings, size: 72, color: Colors.white24),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.isDemo)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    color: const Color(0x33FFC107),
                    child: Text(app.t('demo'),
                        style: const TextStyle(color: Colors.amber)),
                  ),
                Text(app.pname(p),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(money(p.priceMinor, p.currency),
                    style: const TextStyle(
                        color: kOrange,
                        fontSize: 26,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(
                  p.stock > 0
                      ? '${p.stock} ${app.t('inStock')}'
                      : app.t('outOfStock'),
                  style: TextStyle(
                      color: p.stock > 0 ? Colors.greenAccent : Colors.redAccent),
                ),
                const SizedBox(height: 12),
                // Seller information (required on every product)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: kDark, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.store, color: kOrange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('${app.t('soldBy')}: ${p.sellerName}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      if (p.sellerVerified)
                        Row(children: [
                          const Icon(Icons.verified,
                              color: Colors.lightBlueAccent, size: 18),
                          const SizedBox(width: 4),
                          Text(app.t('verified'),
                              style: const TextStyle(fontSize: 12)),
                        ]),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(p.description),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            side: const BorderSide(color: kOrange)),
                        onPressed: p.stock < 1
                            ? null
                            : () {
                                final err = app.addToCart(p);
                                toast(context, err ?? 'Added to cart');
                              },
                        child: Text(app.t('addToCart')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: p.stock < 1
                            ? null
                            : () {
                                final err = app.addToCart(p);
                                if (err != null) {
                                  toast(context, err);
                                  return;
                                }
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => const CheckoutScreen()));
                              },
                        child: Text(app.t('buyNow')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(app.t('reviews'),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                        onPressed: _writeReview,
                        child: Text(app.t('writeReview'))),
                  ],
                ),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _reviews,
                  builder: (context, snap) {
                    final list = snap.data ?? [];
                    if (list.isEmpty) return const Text('—');
                    return Column(
                      children: [
                        for (final r in list)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Row(children: [
                              for (var i = 1; i <= 5; i++)
                                Icon(
                                    i <= (r['rating'] as num)
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: kOrange,
                                    size: 16),
                            ]),
                            subtitle: Text((r['comment'] ?? '') as String),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
