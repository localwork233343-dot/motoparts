import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core.dart';
import 'home_screen.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _rate;
  Map<String, dynamic>? _seller;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = sb.auth.currentUser!.id;
    try {
      final p = await sb.from('profiles').select().eq('id', uid).single();
      final rates = await sb.from('currency_rates').select().limit(1);
      final s = await sb.from('sellers').select().eq('user_id', uid);
      if (!mounted) return;
      setState(() {
        _profile = p;
        final rl = List<Map<String, dynamic>>.from(rates);
        _rate = rl.isEmpty ? null : rl.first;
        final sl = List<Map<String, dynamic>>.from(s);
        _seller = sl.isEmpty ? null : sl.first;
      });
    } catch (_) {}
  }

  Future<void> _support() async {
    final app = context.read<AppState>();
    final subject = TextEditingController();
    final message = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(app.t('support')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: subject,
              decoration: const InputDecoration(labelText: 'Subject')),
          const SizedBox(height: 8),
          TextField(
              controller: message,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Message')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(app.t('cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(app.t('send'))),
        ],
      ),
    );
    if (ok != true || subject.text.trim().isEmpty || message.text.trim().isEmpty) {
      return;
    }
    try {
      await sb.from('support_tickets').insert({
        'user_id': sb.auth.currentUser!.id,
