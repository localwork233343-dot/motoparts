import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient get sb => Supabase.instance.client;

// ---------- brand ----------
const kOrange = Color(0xFFFF6A00);
const kBlack = Color(0xFF0B0B0B);
const kDark = Color(0xFF1E1E1E);
const kGrey = Color(0xFF2A2A2A);

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kBlack,
    colorScheme: const ColorScheme.dark(
      primary: kOrange,
      secondary: kOrange,
      surface: kDark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kBlack,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kOrange,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kGrey,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

// ---------- translations ----------
const Map<String, Map<String, String>> _tr = {
  'en': {
    'slogan': 'Ride Better. Buy Smarter.',
    'shop': 'Shop',
    'cart': 'Cart',
    'orders': 'Orders',
    'account': 'Account',
    'search': 'Search parts...',
    'all': 'All',
    'myBike': 'My Bike',
    'noProducts': 'No products found',
    'addToCart': 'Add to Cart',
    'buyNow': 'Buy Now',
    'soldBy': 'Sold by',
    'verified': 'Verified shop',
    'inStock': 'in stock',
    'outOfStock': 'Out of stock',
    'demo': 'DEMO product - sample price',
    'signIn': 'Sign in',
    'signUp': 'Create account',
    'email': 'Email',
    'password': 'Password',
    'name': 'Full name',
    'cartEmpty': 'Your cart is empty',
    'subtotal': 'Subtotal',
    'shipping': 'Shipping',
    'discount': 'Discount',
    'total': 'Total',
    'checkout': 'Checkout',
    'placeOrder': 'Place order',
    'coupon': 'Coupon code (optional)',
    'address': 'Delivery address',
    'payment': 'Payment method',
    'comingSoon': 'Needs merchant account / gateway keys',
    'orderPlaced': 'Order placed!',
    'signOut': 'Sign out',
    'language': 'Language',
    'country': 'Country / Market',
    'currency': 'Currency',
    'wishlist': 'Wishlist',
    'notifications': 'Notifications',
    'support': 'Customer support',
    'becomeSeller': 'Become a seller',
    'reviews': 'Reviews',
    'writeReview': 'Write a review',
    'save': 'Save',
    'cancel': 'Cancel',
    'send': 'Send',
    'rates': 'Exchange rate (display only)',
  },
  'bn': {
    'slogan': 'ভালো চালান। স্মার্ট কিনুন।',
    'shop': 'শপ',
    'cart': 'কার্ট',
    'orders': 'অর্ডার',
    'account': 'অ্যাকাউন্ট',
    'search': 'পার্টস খুঁজুন...',
    'all': 'সব',
    'myBike': 'আমার বাইক',
    'noProducts': 'কোনো পণ্য পাওয়া যায়নি',
    'addToCart': 'কার্টে যোগ করুন',
    'buyNow': 'এখনই কিনুন',
    'soldBy': 'বিক্রেতা',
    'verified': 'ভেরিফাইড শপ',
    'inStock': 'স্টকে আছে',
    'outOfStock': 'স্টক নেই',
    'demo': 'ডেমো পণ্য - নমুনা দাম',
    'signIn': 'সাইন ইন',
    'signUp': 'অ্যাকাউন্ট খুলুন',
    'email': 'ইমেইল',
    'password': 'পাসওয়ার্ড',
    'name': 'পুরো নাম',
    'cartEmpty': 'আপনার কার্ট খালি',
    'subtotal': 'সাবটোটাল',
    'shipping': 'ডেলিভারি চার্জ',
    'discount': 'ডিসকাউন্ট',
    'total': 'মোট',
    'checkout': 'চেকআউট',
    'placeOrder': 'অর্ডার করুন',
    'coupon': 'কুপন কোড (ঐচ্ছিক)',
    'address': 'ডেলিভারি ঠিকানা',
    'payment': 'পেমেন্ট পদ্ধতি',
    'comingSoon': 'মার্চেন্ট অ্যাকাউন্ট / গেটওয়ে কী লাগবে',
    'orderPlaced': 'অর্ডার হয়েছে!',
    'signOut': 'সাইন আউট',
    'language': 'ভাষা',
    'country': 'দেশ / মার্কেট',
    'currency': 'মুদ্রা',
    'wishlist': 'উইশলিস্ট',
    'notifications': 'নোটিফিকেশন',
    'support': 'কাস্টমার সাপোর্ট',
    'becomeSeller': 'বিক্রেতা হোন',
    'reviews': 'রিভিউ',
    'writeReview': 'রিভিউ লিখুন',
    'save': 'সংরক্ষণ',
    'cancel': 'বাতিল',
    'send': 'পাঠান',
    'rates': 'এক্সচেঞ্জ রেট (শুধু দেখানোর জন্য)',
  },
};

// ---------- money (integer minor units + currency code) ----------
String money(int minor, String currency) {
  final sym = currency == 'BDT' ? '৳' : '\$';
  return '$sym${(minor / 100).toStringAsFixed(2)}';
}

// ---------- models ----------
class Product {
  final String id;
  final String sellerId;
  final String name;
  final String? nameBn;
  final String description;
  final int priceMinor;
  final String currency;
  final int stock;
  final List<String> images;
  final bool isDemo;
  final String sellerName;
  final bool sellerVerified;

  Product({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.nameBn,
    required this.description,
    required this.priceMinor,
    required this.currency,
    required this.stock,
    required this.images,
    required this.isDemo,
    required this.sellerName,
    required this.sellerVerified,
  });

  factory Product.fromJson(Map<String, dynamic> j) {
    final s = j['sellers'];
    return Product(
      id: j['id'] as String,
      sellerId: j['seller_id'] as String,
      name: j['name'] as String,
      nameBn: j['name_bn'] as String?,
      description: (j['description'] ?? '') as String,
      priceMinor: (j['price_minor'] as num).toInt(),
      currency: j['currency'] as String,
      stock: (j['stock'] as num).toInt(),
      images: ((j['images'] ?? []) as List).map((e) => e.toString()).toList(),
      isDemo: (j['is_demo'] ?? false) as bool,
      sellerName: s is Map ? (s['shop_name'] ?? '') as String : '',
      sellerVerified: s is Map ? (s['verified'] ?? false) as bool : false,
    );
  }
}

class CartLine {
  final Product product;
  int qty;
  CartLine(this.product, this.qty);
}

class Vehicle {
  final int modelId;
  final String label;
  final int year;
  Vehicle(this.modelId, this.label, this.year);
}

// ---------- app state ----------
class AppState extends ChangeNotifier {
  String lang = 'en';
  String country = 'US';
  String currency = 'USD';
  Vehicle? vehicle;
  final Map<String, CartLine> cart = {};

  String t(String key) => _tr[lang]?[key] ?? _tr['en']![key] ?? key;
    String pname(Product p) =>
      (lang == 'bn' && (p.nameBn ?? '').isNotEmpty) ? p.nameBn! : p.name;

  void notify() => notifyListeners();
}

// ---------- helpers added to fix build ----------
extension CartHelper on AppState {
  String? addToCart(Product p, {int qty = 1}) {
    if (p.stock <= 0) return t('outOfStock');
    final existing = cart[p.id];
    final newQty = (existing?.qty ?? 0) + qty;
    if (newQty > p.stock) return t('outOfStock');
    if (existing != null) {
      existing.qty = newQty;
    } else {
      cart[p.id] = CartLine(p, qty);
    }
    notifyListeners();
    return null;
  }
}

String errText(Object e) => e.toString();

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}
