import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core.dart';

class Logo extends StatelessWidget {
  final double size;
  const Logo({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: kOrange,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.two_wheeler, color: Colors.white, size: size),
        ),
        const SizedBox(width: 8),
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
            children: const [
              TextSpan(text: 'MOTO'),
              TextSpan(text: 'PARTS', style: TextStyle(color: kOrange)),
              TextSpan(text: ' USA'),
            ],
          ),
        ),
      ],
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  bool _signup = false;
  bool _busy = false;

  Future<void> _submit() async {
    final app = context.read<AppState>();
    final email = _email.text.trim();
    final pass = _pass.text;
    if (!email.contains('@') || pass.length < 8) {
      toast(context, 'Enter a valid email and a password of 8+ characters.');
      return;
    }
    setState(() => _busy = true);
    try {
      if (_signup) {
        final res = await sb.auth.signUp(
          email: email,
          password: pass,
          data: {'full_name': _name.text.trim(), 'country': app.country},
        );
        if (res.session == null && mounted) {
          toast(context, 'Check your email to confirm your account, then sign in.');
          setState(() => _signup = false);
        }
      } else {
        await sb.auth.signInWithPassword(email: email, password: pass);
      }
    } catch (e) {
      if (mounted) toast(context, errText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Logo(size: 34),
                const SizedBox(height: 8),
                Text(app.t('slogan'),
                    style: const TextStyle(color: kOrange, letterSpacing: 1)),
                const SizedBox(height: 28),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'US', label: Text('USA  \$')),
                    ButtonSegment(value: 'BD', label: Text('বাংলাদেশ  ৳')),
                  ],
                  selected: {app.country},
                  onSelectionChanged: (s) => app.setCountry(s.first),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'en', label: Text('English')),
                    ButtonSegment(value: 'bn', label: Text('বাংলা')),
                  ],
                  selected: {app.lang},
                  onSelectionChanged: (s) => app.setLang(s.first),
                ),
                const SizedBox(height: 20),
                if (_signup) ...[
                  TextField(
                    controller: _name,
                    decoration: InputDecoration(labelText: app.t('name')),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: app.t('email')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pass,
                  obscureText: true,
                  decoration: InputDecoration(labelText: app.t('password')),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_signup ? app.t('signUp') : app.t('signIn')),
                ),
                TextButton(
                  onPressed: () => setState(() => _signup = !_signup),
                  child: Text(_signup ? app.t('signIn') : app.t('signUp')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
