import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/pages/auth_page.dart';
import 'src/pages/home_page.dart';
import 'src/theme/app_theme.dart';
import 'src/config/env.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

 
  final defineUrl = const String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  final defineKey = const String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  
  final supabaseUrl =
      defineUrl.isNotEmpty ? defineUrl : Env.fallbackSupabaseUrl;
  final supabaseAnonKey =
      defineKey.isNotEmpty ? defineKey : Env.fallbackSupabaseAnonKey;

  

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SupaBlog Files',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final user = Supabase.instance.client.auth.currentUser;
          return user == null ? const AuthPage() : const HomePage();
        },
      ),
    );
  }
}
