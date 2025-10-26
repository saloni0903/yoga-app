// main.dart
import 'screens/home/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';

import 'providers/language_provider.dart';
import 'api_service.dart';
import 'models/user.dart'; 
import 'theme_provider.dart';
import 'package:provider/provider.dart';

import 'package:flutter/material.dart';
import 'package:yoga_app/screens/qr/qr_scanner_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'package:yoga_app/generated/app_localizations.dart';


final seed = const Color(0xFF2E7D6E);
final surfaceTint = const Color(0xFF204D45);

@pragma('vm:entry-point') // Required for release mode AOT compilation
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if needed for background tasks
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
  // You might want to show a local notification here using flutter_local_notifications
  // but keep this handler minimal as it runs in a separate isolate.
}

Future<void> main() async  {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApiService()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          return MyApp(
            themeProvider: themeProvider,
            languageProvider: languageProvider,
          );
        },
      ),
    ),
  );
}

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  late Future<bool> _checkOnboardingFuture;

  @override
  void initState() {
    super.initState();
    _checkOnboardingFuture = _checkIfOnboardingSeen();
  }
  Future<bool> _checkIfOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hasSeenOnboarding') ?? false;
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkOnboardingFuture,
      builder: (context, snapshot) {
        // While checking, show a loading circle
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final hasSeenOnboarding = snapshot.data ?? false;
        if (hasSeenOnboarding) {
          return const AuthWrapper();
        } else {
          return const OnboardingScreen();
        }
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}
class _AuthWrapperState extends State<AuthWrapper> {
  ApiService? _apiService;
  bool _notificationsInitialized = false;

  @override
  void initState() {
    super.initState();
    _attemptAutoLoginAndInitNotifications();
    Provider.of<ApiService>(context, listen: false).tryAutoLogin();
  }

  Future<void> _attemptAutoLoginAndInitNotifications() async {
    // Get ApiService once, without listening in initState
    final apiService = Provider.of<ApiService>(context, listen: false);
    final loggedIn = await apiService.tryAutoLogin();

    // IMPORTANT: Check if the widget is still mounted after async work
    if (loggedIn && mounted && !_notificationsInitialized) {
      print("[AuthWrapper] Auto-login successful. Initializing notifications...");
      try {
        // Initialize notifications using the current context
        await FirebaseNotificationService.initialize(context);
        // Safely update state if still mounted
        if (mounted) {
          setState(() { _notificationsInitialized = true; });
        }
      } catch (e) {
        print("[AuthWrapper] Error initializing notifications after auto-login: $e");
        // Handle potential errors (e.g., context issues if user navigates away fast)
      }
    } else if (loggedIn) {
         print("[AuthWrapper] Auto-login successful but notifications already initialized this session.");
    } else {
        print("[AuthWrapper] Auto-login failed.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiService>(
      builder: (context, apiService, child) {
        if (apiService.isAuthenticated) {
          if (!_notificationsInitialized) {
             print("[AuthWrapper] Manual login detected or state restored. Initializing notifications...");
             // Use addPostFrameCallback to run *after* the current build frame
             WidgetsBinding.instance.addPostFrameCallback((_) async {
               // Double-check mounted status and flag inside the callback
               if (mounted && !_notificationsInitialized) {
                 try {
                     await FirebaseNotificationService.initialize(context);
                     // Safely update state after async work inside callback
                     if (mounted) {
                        setState(() { _notificationsInitialized = true; });
                     }
                 } catch(e) {
                     print("[AuthWrapper] Error initializing notifications after manual login/restore: $e");
                 }
               }
            });
          }
          return HomeScreen(
            apiService: apiService,
            user: apiService.currentUser!,
          );
        } else {
          if (_notificationsInitialized) {
              print("[AuthWrapper] User logged out. Resetting notification flag.");
             // Use addPostFrameCallback to safely update state *after* the build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                 if (mounted) { // Check if widget is still in the tree
                    setState(() { _notificationsInitialized = false; });
                 } else {
                     _notificationsInitialized = false; // Reset anyway if not mounted
                 }
              });
          }
          return const LoginScreen();
        }
      },
    );
  }
}

class MyApp extends StatelessWidget {

  final ThemeProvider themeProvider;
  final LanguageProvider languageProvider;

  const MyApp({super.key, required this.themeProvider, required this.languageProvider});

  @override
  Widget build(BuildContext context) {
    final lightBase = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
      ),
    );

    final darkBase = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
      ),
    );

    // Light Theme: Uses semantic colors from the ColorScheme for consistency.
    final lightTheme = lightBase.copyWith(
      scaffoldBackgroundColor: lightBase.colorScheme.background,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: surfaceTint.withOpacity(0.06),
        backgroundColor: lightBase.colorScheme.surface,
        foregroundColor: lightBase.colorScheme.onSurface,
        titleTextStyle: lightBase.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      textTheme: lightBase.textTheme
          .apply(
            bodyColor: lightBase.colorScheme.onBackground,
            displayColor: lightBase.colorScheme.onBackground,
          )
          .copyWith(
            headlineLarge: lightBase.textTheme.headlineLarge
                ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4),
            headlineMedium: lightBase.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
            titleLarge: lightBase.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
            bodyLarge: lightBase.textTheme.bodyLarge
                ?.copyWith(height: 1.28, letterSpacing: 0.1),
          ),
      cardTheme: CardThemeData(
        color: lightBase.colorScheme.surface,
        elevation: 1,
        shadowColor: lightBase.colorScheme.shadow.withOpacity(0.5),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: lightBase.colorScheme.primary,
          foregroundColor: lightBase.colorScheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: lightBase.textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          side: BorderSide(color: lightBase.colorScheme.outlineVariant, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          foregroundColor: lightBase.colorScheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightBase.colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: lightBase.colorScheme.onSurfaceVariant),
        labelStyle: TextStyle(
            color: lightBase.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: lightBase.colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: lightBase.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: lightBase.colorScheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: lightBase.colorScheme.error),
        ),
        prefixIconColor: lightBase.colorScheme.onSurfaceVariant,
      ),
      chipTheme: lightBase.chipTheme.copyWith(
        shape: StadiumBorder(side: BorderSide(color: lightBase.colorScheme.outlineVariant)),
        labelStyle: TextStyle(color: lightBase.colorScheme.onSurface),
      ),
      dividerTheme: DividerThemeData(
          color: lightBase.colorScheme.outlineVariant, space: 24, thickness: 1),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        indicatorColor: lightBase.colorScheme.secondaryContainer,
        backgroundColor: lightBase.colorScheme.surface,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 1,
        backgroundColor: lightBase.colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: lightBase.colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 2,
        backgroundColor: lightBase.colorScheme.surface,
        surfaceTintColor: lightBase.colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightBase.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      iconTheme: IconThemeData(color: lightBase.colorScheme.onSurfaceVariant),
    );

    // Dark Theme: Perfectly mirrors the light theme's structure using semantic colors.
    final darkTheme = darkBase.copyWith(
      scaffoldBackgroundColor: darkBase.colorScheme.background,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: surfaceTint.withOpacity(0.06),
        backgroundColor: darkBase.colorScheme.surface,
        foregroundColor: darkBase.colorScheme.onSurface,
        titleTextStyle: darkBase.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      textTheme: darkBase.textTheme
          .apply(
            bodyColor: darkBase.colorScheme.onBackground,
            displayColor: darkBase.colorScheme.onBackground,
          )
          .copyWith(
            headlineLarge: darkBase.textTheme.headlineLarge
                ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4),
            headlineMedium: darkBase.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
            titleLarge: darkBase.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
            bodyLarge: darkBase.textTheme.bodyLarge
                ?.copyWith(height: 1.28, letterSpacing: 0.1),
          ),
      cardTheme: CardThemeData(
        color: darkBase.colorScheme.surface,
        elevation: 1,
        shadowColor: darkBase.colorScheme.shadow,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: darkBase.colorScheme.primary,
          foregroundColor: darkBase.colorScheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: darkBase.textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          side: BorderSide(color: darkBase.colorScheme.outlineVariant, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          foregroundColor: darkBase.colorScheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBase.colorScheme.surfaceVariant.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: darkBase.colorScheme.onSurfaceVariant),
        labelStyle: TextStyle(
            color: darkBase.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: darkBase.colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: darkBase.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: darkBase.colorScheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: darkBase.colorScheme.error),
        ),
        prefixIconColor: darkBase.colorScheme.onSurfaceVariant,
      ),
      chipTheme: darkBase.chipTheme.copyWith(
        shape: StadiumBorder(side: BorderSide(color: darkBase.colorScheme.outlineVariant)),
        labelStyle: TextStyle(color: darkBase.colorScheme.onSurface),
      ),
      dividerTheme: DividerThemeData(
          color: darkBase.colorScheme.outlineVariant, space: 24, thickness: 1),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        indicatorColor: darkBase.colorScheme.secondaryContainer,
        backgroundColor: darkBase.colorScheme.surface,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 1,
        backgroundColor: darkBase.colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: darkBase.colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 2,
        backgroundColor: darkBase.colorScheme.surface,
        surfaceTintColor: darkBase.colorScheme.surfaceTint,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkBase.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      iconTheme: IconThemeData(color: darkBase.colorScheme.onSurfaceVariant),
    );

    return MaterialApp(
      title: 'YES Yoga App',
      locale: languageProvider.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: lightTheme, // <-- THIS IS THE FIX
      darkTheme: darkTheme,
      home: const AppEntry(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/qr-scanner': (context) => const QrScannerScreen(),
      },
    );
  }
}
