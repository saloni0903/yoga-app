import 'api_service.dart';
import 'models/user.dart'; 
import 'theme_provider.dart';
// import 'screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'screens/home/home_screen.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'package:yoga_app/screens/qr/qr_scanner_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApiService()), // Create it here
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MyApp(themeProvider: themeProvider);
        },
      ),
    ),
  );
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late Future<void> _autoLoginFuture;

  @override
  void initState() {
    super.initState();
    // Start the auto-login process when this widget is first created.
    _autoLoginFuture = Provider.of<ApiService>(context, listen: false).tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _autoLoginFuture,
      builder: (context, snapshot) {
        // While the auto-login is running, show a loading circle.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // After the attempt, use the Consumer to check the result.
        return Consumer<ApiService>(
          builder: (context, apiService, child) {
            if (apiService.isAuthenticated) {
              return HomeScreen(
                apiService: apiService,
                user: apiService.currentUser!,
              );
            } else {
              return const LoginScreen();
            }
          },
        );
      },
    );
  }
}


class MyApp extends StatelessWidget {

  final ThemeProvider themeProvider;
  const MyApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final seed = const Color(0xFF2E7D6E);
    final surfaceTint = const Color(0xFF204D45);

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

    final lightTheme = lightBase.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF8FAF9),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: surfaceTint.withOpacity(0.06),
        backgroundColor: Colors.white,
        foregroundColor: lightBase.colorScheme.onSurface,
        titleTextStyle: lightBase.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      textTheme: lightBase.textTheme
          .apply(
            bodyColor: const Color(0xFF24312E),
            displayColor: const Color(0xFF1C2624),
          )
          .copyWith(
            headlineLarge: lightBase.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
            headlineMedium: lightBase.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
            titleLarge: lightBase.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            bodyLarge: lightBase.textTheme.bodyLarge?.copyWith(
              height: 1.28,
              letterSpacing: 0.1,
            ),
          ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          side: BorderSide(
            color: lightBase.colorScheme.outlineVariant,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          foregroundColor: lightBase.colorScheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: Colors.grey.shade500),
        labelStyle: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: lightBase.colorScheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: lightBase.colorScheme.error),
        ),
        prefixIconColor: Colors.grey.shade600,
      ),
      chipTheme: lightBase.chipTheme.copyWith(
        shape: StadiumBorder(
          side: BorderSide(color: lightBase.colorScheme.outlineVariant),
        ),
        labelStyle: TextStyle(color: lightBase.colorScheme.onSurface),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade300,
        space: 24,
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        indicatorColor: lightBase.colorScheme.primaryContainer.withOpacity(0.6),
        backgroundColor: Colors.white,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 1,
        backgroundColor: const Color(0xFF24312E),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 2,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF3A4B47)),
    );

    final darkTheme = darkBase.copyWith(
      // We are adding the same AppBarTheme from the light theme
      // so the style (center title, font weight) remains consistent.
      inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade800, // A dark color for the field background
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: darkBase.colorScheme.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: darkBase.colorScheme.error),
      ),
    ),

      appBarTheme: darkBase.appBarTheme.copyWith(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: surfaceTint.withOpacity(0.06),
        titleTextStyle: darkBase.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),

      // This ensures your text styles are also consistent
      textTheme: darkBase.textTheme.copyWith(
        titleLarge: darkBase.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: Colors.black26,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  

    return MaterialApp(
      title: 'YES Yoga App',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: lightTheme, // <-- THIS IS THE FIX
      darkTheme: darkTheme,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/qr-scanner': (context) => const QrScannerScreen(),
      },
    );
  }
}
