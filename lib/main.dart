import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'routes/navRoutes.dart';
import 'screens/sign_in_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CargoMate',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF7C3AED),
      ),
      initialRoute: NavRoutes.onboarding,
      routes: NavRoutes.routes,
      onGenerateRoute: (settings) {
        final session = Supabase.instance.client.auth.currentSession;
        final isAuthPath = settings.name == NavRoutes.signIn;
        if (session == null && !isAuthPath) {
          return MaterialPageRoute(builder: (_) => const SignInPage());
        }
        return null;
      },
    );
  }
}
