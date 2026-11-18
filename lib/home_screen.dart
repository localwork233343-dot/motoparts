import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'account_screen.dart';
import 'auth_screen.dart';
import 'cart_screen.dart';
import 'core.dart';
import 'orders_screen.dart';
import 'product_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pages = const [CatalogPage(), CartPage(), OrdersPage(), AccountPage()];
    return Scaffold(
      body: SafeArea(child: pages[_tab]),
      bottomNavigationBar: NavigationBar(
        backgroundColor: kDark,
        indicatorColor: kOrange,
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.storefront_outlined), label: app.t('shop')),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: app.cartCount > 0,
              label: Text('${app.cartCount}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            label: app.t('cart'),
          ),
          NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              label: app.t('orders')),
          NavigationDestination(
              icon: const Icon(Icons.person_outline), label: app.t('account')),
        ],
      ),
    );
  }
}

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _cats = [];
  int? _parent;
  Future<List<Product>>? _future;
  String _lastKey = '';

  @override
  void initState() {
    super.initState();
    _loadCats();
  }

  Future<void> _loadCats() async {
    try {
      final r = await sb.from('categories').select().order('sort');
      if (mounted) setState(() => _cats = List<Map<String, dynamic>>.from(r));
    } catch (_) {}
  }

  Future<List<Product>> _fetch(AppState app) async {
    var q = sb
        .from('products')
        .select('*, sellers(shop_name, verified)')
        .eq('active', true)
        .eq('currency', app.currency);

    if (_parent != null) {
      final ids = _cats
          .where((c) => c['parent_id'] == _parent)
          .map((c) => c['id'])
          .toList();
      q = q.inFilter('category_id', ids);
    }
    final text = _search.text.trim();
    if (text.isNotEmpty) {
      q = q.ilike('name', '%$text%');
    }
    if (app.vehicle != null) {
      final r = await sb
          .from('product_compat')
          .select('product_id')
          .eq('model_id', app.vehicle!.modelId);
      final ids = List<Map<String, dynamic>>.from(r)
          .map((e) => e['product_id'] as String)
          .toList();
      q = q.inFilter('id', ids);
    }
    final rows = await q.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows)
        .map((j) => Product.fromJson(j))
        .toList();
  }

  void _refresh() => setState(() => _lastKey = '');

  Future<void> _pickVehicle(AppState app) async {
    final v = await showModalBottomSheet<Vehicle?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kDark,
      builder: (_) => const _VehiclePicker(),
    );
    if (v != null) {
      app.setVehicle(v.modelId == -1 ? null : v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final key =
        '${app.currency}|${app.vehicle?.modelId}|$_parent|${_search.text}';
    if (key != _lastKey || _future == null) {
      _lastKey = key;
      _future = _fetch(app);
    }
    final parents = _cats.where((c) => c['parent_id'] == null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Logo(size: 22),
              Text(app.currency,
                  style: const TextStyle(
                      color: kOrange, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(app.t('slogan'),
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _refresh(),
                  decoration: InputDecoration(
                    hintText: app.t('search'),
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: kOrange),
                onPressed: () => _pickVehicle(app),
                icon: const Icon(Icons.two_wheeler),
                tooltip: app.t('myBike'),
              ),
            ],
          ),
        ),
        if (app.vehicle != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: InputChip(
              label: Text('${app.vehicle!.label} (${app.vehicle!.year})'),
              onDeleted: () => app.setVehicle(null),
            ),
          ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: ChoiceChip(
                  label: Text(app.t('all')),
                  selected: _parent == null,
                  onSelected: (_) => setState(() => _parent = null),
                ),
              ),
              for (final c in parents)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: ChoiceChip(
                    label: Text(
                        app.lang == 'bn' ? c['name_bn'] as String : c['name_en'] as String),
                    selected: _parent == c['id'],
                    onSelected: (_) => setState(() => _parent = c['id'] as int),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Product>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text(errText(snap.error!)));
              }
              final items = snap.data ?? [];
              if (items.isEmpty) {
                return Center(child: Text(app.t('noProducts')));
              }
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) => ProductCard(product: items[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final p = product;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProductScreen(product: p)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: kDark,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: kGrey,
                child: p.images.isNotEmpty
                    ? Image.network(p.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _NoImage())
                    : const _NoImage(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.pname(p),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(money(p.priceMinor, p.currency),
                      style: const TextStyle(
                          color: kOrange,
                          fontWeight: FontWeight.w900,
                          fontSize: 16)),
                  Text(p.sellerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 11)),
                  if (p.isDemo)
                    const Text('DEMO',
                        style: TextStyle(color: Colors.amber, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoImage extends StatelessWidget {
  const _NoImage();
  @override
  Widget build(BuildContext context) =>
      const Center(child: Icon(Icons.settings, size: 48, color: Colors.white24));
}

class _VehiclePicker extends StatefulWidget {
  const _VehiclePicker();

  @override
  State<_VehiclePicker> createState() => _VehiclePickerState();
}

class _VehiclePickerState extends State<_VehiclePicker> {
  List<Map<String, dynamic>> _brands = [];
  List<Map<String, dynamic>> _models = [];
  int? _brand;
  Map<String, dynamic>? _model;
  int? _year;

  @override
  void initState() {
    super.initState();
    sb.from('brands').select().order('name').then((r) {
      if (mounted) setState(() => _brands = List<Map<String, dynamic>>.from(r));
    });
  }

  Future<void> _loadModels(int brandId) async {
    final r = await sb
        .from('motorcycle_models')
        .select()
        .eq('brand_id', brandId)
        .order('name');
    if (mounted) {
      setState(() {
        _models = List<Map<String, dynamic>>.from(r);
        _model = null;
        _year = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final years = <int>[];
    if (_model != null) {
      final from = (_model!['year_from'] as num).toInt();
      final to = ((_model!['year_to'] ?? 2026) as num).toInt();
      for (var y = to; y >= from; y--) {
        years.add(y);
      }
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(app.t('myBike'),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: 'Brand'),
            items: [
              for (final b in _brands)
                DropdownMenuItem(
                    value: b['id'] as int, child: Text(b['name'] as String)),
            ],
            onChanged: (v) {
              setState(() => _brand = v);
              if (v != null) _loadModels(v);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Map<String, dynamic>>(
            key: ValueKey('model$_brand'),
            decoration: const InputDecoration(labelText: 'Model / Engine cc'),
            items: [
              for (final m in _models)
                DropdownMenuItem(
                    value: m, child: Text('${m['name']} (${m['engine_cc']}cc)')),
            ],
            onChanged: (v) => setState(() {
              _model = v;
              _year = null;
            }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            key: ValueKey('year${_model?['id']}'),
            decoration: const InputDecoration(labelText: 'Year'),
            items: [
              for (final y in years) DropdownMenuItem(value: y, child: Text('$y')),
            ],
            onChanged: (v) => setState(() => _year = v),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: (_model == null || _year == null)
                ? null
                : () => Navigator.pop(
                      context,
                      Vehicle(
                        (_model!['id'] as num).toInt(),
                        '${_model!['name']} ${_model!['engine_cc']}cc',
                        _year!,
                      ),
                    ),
            child: Text(app.t('save')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, Vehicle(-1, '', 0)),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
