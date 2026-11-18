import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _rate;

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
      if (!mounted) return;
      setState(() {
        _profile = p;
        final rl = List<Map<String, dynamic>>.from(rates);
        _rate = rl.isEmpty ? null : rl.first;
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
    if (ok != true ||
        subject.text.trim().isEmpty ||
        message.text.trim().isEmpty) {
      return;
    }
    try {
      await sb.from('support_tickets').insert({
        'user_id': sb.auth.currentUser!.id,
        'subject': subject.text.trim(),
        'message': message.text.trim(),
      });
      if (mounted) toast(context, app.t('send'));
    } catch (e) {
      if (mounted) toast(context, errText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final user = sb.auth.currentUser;
    final name = (_profile?['full_name'] ?? user?.email ?? '') as String;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const CircleAvatar(
              backgroundColor: kOrange, child: Icon(Icons.person)),
          title: Text(name),
          subtitle: Text(user?.email ?? ''),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(app.t('language')),
          trailing: DropdownButton<String>(
            value: app.lang,
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'bn', child: Text('বাংলা')),
            ],
            onChanged: (v) {
              if (v != null) app.setLang(v);
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.public),
          title: Text(app.t('country')),
          trailing: DropdownButton<String>(
            value: app.country,
            items: const [
              DropdownMenuItem(value: 'US', child: Text('USA')),
              DropdownMenuItem(value: 'BD', child: Text('Bangladesh')),
            ],
            onChanged: (v) {
              if (v != null) app.setCountry(v);
            },
          ),
        ),
        if (_rate != null)
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: Text(app.t('rates')),
            subtitle: Text('${_rate!['rate']}'),
          ),
        ListTile(
          leading: const Icon(Icons.support_agent),
          title: Text(app.t('support')),
          onTap: _support,
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: Text(app.t('signOut')),
          onTap: () async {
            await sb.auth.signOut();
          },
        ),
      ],
    );
  }
}
