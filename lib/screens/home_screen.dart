import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/language_provider.dart';
import '../providers/location_provider.dart';
import '../providers/route_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/amigo_logo.dart';
import 'route_planning_screen.dart';
import 'chatbot_screen.dart';
import 'username_login_screen.dart';
import 'manage_account_screen.dart';

/// Main Home Screen
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Defer location so the first frame(s) paint without competing with GMS/Geolocator init.
    // Reduces "Skipped frames" and ANR when opening the app or navigating to Search Route.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        context.read<LocationProvider>().getCurrentLocation().catchError((error) {
          debugPrint('Location error: $error');
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final routeProvider = context.watch<RouteProvider>();
    final authProvider = context.watch<AuthProvider>();

    final isLoggedIn = authProvider.isInitialized && authProvider.isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('app_title')),
        actions: [
          // Share my location (one tap → share sheet with map link)
          IconButton(
            icon: const Icon(Icons.share_location),
            tooltip: languageProvider.isSpanish ? 'Compartir ubicación' : 'Share my location',
            onPressed: () => _shareMyLocation(context, languageProvider, locationProvider),
          ),
          // Emergency: dial 911 (top right, always visible)
          IconButton(
            icon: const Icon(Icons.emergency),
            tooltip: languageProvider.isSpanish ? 'Llamar al 911' : 'Call 911',
            onPressed: () async {
              final uri = Uri.parse('tel:911');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        languageProvider.isSpanish
                            ? 'No se puede marcar. Use el teléfono directamente.'
                            : 'Cannot place call. Use your phone directly.',
                      ),
                    ),
                  );
                }
              }
            },
          ),
          // Manage account (only when user is logged in)
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: languageProvider.isSpanish
                  ? 'Gestionar cuenta'
                  : 'Manage account',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManageAccountScreen(),
                  ),
                );
              },
            ),
          // Language Toggle
          IconButton(
            icon: Icon(
                languageProvider.isEnglish ? Icons.language : Icons.translate),
            onPressed: () => languageProvider.toggleLanguage(),
            tooltip: languageProvider.isEnglish
                ? 'Switch to Spanish'
                : 'Cambiar a Inglés',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: isLoggedIn
              ? _buildLoggedInContent(
                  context,
                  languageProvider,
                  locationProvider,
                )
              : _buildOnboardingContent(context, languageProvider),
        ),
      ),
    );
  }

  Widget _buildOnboardingContent(
    BuildContext context,
    LanguageProvider languageProvider,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.person_pin_circle,
          size: 90,
          color: Colors.purple,
        ),
        const SizedBox(height: 20),
        Text(
          languageProvider.isSpanish
              ? 'Tu perfil de viaje'
              : 'Your travel profile',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          languageProvider.isSpanish
              ? 'Elige un nombre sencillo para que podamos recordar tus rutas favoritas y sugerirte viajes rápidamente.'
              : 'Choose a simple username so we can remember your favorite routes and suggest trips instantly.',
          style: const TextStyle(fontSize: 14, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UsernameLoginScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              languageProvider.isSpanish
                  ? 'Comenzar'
                  : 'Get started',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoggedInContent(
    BuildContext context,
    LanguageProvider languageProvider,
    LocationProvider locationProvider,
  ) {
    final auth = context.watch<AuthProvider>();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (auth.username != null && auth.username!.isNotEmpty) ...[
          Text(
            languageProvider.isSpanish
                ? 'Bienvenido, ${auth.username}!'
                : 'Welcome, ${auth.username}!',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
        ],
        const AmigoLogo(size: 86),
        const SizedBox(height: 20),
        Text(
          languageProvider.translate('app_title'),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Location Status (only show if location is available, not errors)
        if (locationProvider.isLoading)
          const CircularProgressIndicator()
        else if (locationProvider.hasLocation)
          Text(
            'Location: ${locationProvider.currentLocation!.latitude.toStringAsFixed(4)}, ${locationProvider.currentLocation!.longitude.toStringAsFixed(4)}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        const SizedBox(height: 16),

        // Action buttons in a row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Search Route button
            _buildActionButton(
              context,
              Icons.route,
              languageProvider.translate('search_button'),
              Colors.blue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RoutePlanningScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            // Chatbot Assistant button
            _buildActionButton(
              context,
              Icons.chat_bubble_outline,
              languageProvider.isSpanish ? 'Asistente IA' : 'AI Assistant',
              Colors.purple,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChatbotScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _shareMyLocation(
    BuildContext context,
    LanguageProvider languageProvider,
    LocationProvider locationProvider,
  ) async {
    double? lat = locationProvider.currentLocation?.latitude;
    double? lng = locationProvider.currentLocation?.longitude;
    if (lat == null || lng == null) {
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          await Geolocator.requestPermission();
        }
        if (await Geolocator.isLocationServiceEnabled()) {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 5),
          );
          lat = pos.latitude;
          lng = pos.longitude;
        }
      } catch (_) {}
    }
    if (lat == null || lng == null || !context.mounted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageProvider.isSpanish
                  ? 'No se pudo obtener la ubicación. Activa el GPS e intenta de nuevo.'
                  : 'Could not get location. Enable GPS and try again.',
            ),
          ),
        );
      }
      return;
    }
    final url = 'https://www.google.com/maps?q=$lat,$lng';
    final text = languageProvider.isSpanish
        ? 'Mi ubicación actual: $url'
        : 'My current location: $url';
    try {
      await Share.share(
        text,
        subject: languageProvider.isSpanish ? 'Mi ubicación' : 'My location',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageProvider.isSpanish
                  ? 'Listo para compartir por mensaje o correo.'
                  : 'Ready to share via message or email.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageProvider.isSpanish
                  ? 'Enlace copiado. Pégalo en un mensaje para compartir.'
                  : 'Link copied. Paste it in a message to share.',
            ),
          ),
        );
      }
    }
  }


  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 160),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: Text(
            label,
            style: const TextStyle(fontSize: 13),
            textAlign: TextAlign.center,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
  }
}

