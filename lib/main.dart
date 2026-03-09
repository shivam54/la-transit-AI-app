import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/constants.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'providers/language_provider.dart';
import 'providers/location_provider.dart';
import 'providers/route_provider.dart';
import 'providers/auth_provider.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => RouteProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.purple,
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.purple,
                brightness: Brightness.light,
              ),
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
