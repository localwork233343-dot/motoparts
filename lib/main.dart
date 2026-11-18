import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_screen.dart';
import 'core.dart';
import 'home_screen.dart';

// Provided at build time:  --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    runApp(const _MissingConfig());
    return;
  }
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  final state = AppState();
  await state.load();
  runApp(ChangeNotifierProvider.value(value: state, child: const MotoApp()));
}

class MotoApp extends StatelessWidget {
  const MotoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MotoParts USA',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: StreamBuilder<AuthState>(
        stream: sb.auth.onAuthStateChange,
        builder: (context, snap) {
          final signedIn = sb.auth.currentSession != null;
          return signedIn ? const HomeScreen() : const AuthScreen();
        },
      ),
    );
  }
}

class _MissingConfig extends StatelessWidget {
  const _MissingConfig();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'App is not configured.\nBuild it with SUPABASE_URL and '
              'SUPABASE_ANON_KEY (see README).',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
