// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiService = ApiService();
  await apiService.tryAutoLogin();

  runApp(ChangeNotifierProvider.value(value: apiService, child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = const Color(0xFF2E7D6E); // Calm green-teal for wellness
    final surfaceTint = const Color(0xFF204D45);

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'YES Yoga App',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: base.copyWith(
        // Colors
        scaffoldBackgroundColor: const Color(0xFFF8FAF9),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 2,
          surfaceTintColor: surfaceTint.withOpacity(0.06),
          backgroundColor: Colors.white,
          foregroundColor: base.colorScheme.onSurface,
          titleTextStyle: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),

        // Typography
        textTheme: base.textTheme
            .apply(
              bodyColor: const Color(0xFF24312E),
              displayColor: const Color(0xFF1C2624),
            )
            .copyWith(
              headlineLarge: base.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
              headlineMedium: base.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
              titleLarge: base.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              bodyLarge: base.textTheme.bodyLarge?.copyWith(
                height: 1.28,
                letterSpacing: 0.1,
              ),
            ),

        // Cards & Surfaces
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          shadowColor: Colors.black12,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: base.colorScheme.primary,
            foregroundColor: base.colorScheme.onPrimary,
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
              color: base.colorScheme.outlineVariant,
              width: 1.2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            foregroundColor: base.colorScheme.primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),

        // Inputs
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
            borderSide: BorderSide(color: base.colorScheme.primary, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: base.colorScheme.error),
          ),
          prefixIconColor: Colors.grey.shade600,
        ),

        // Chips
        chipTheme: base.chipTheme.copyWith(
          shape: StadiumBorder(
            side: BorderSide(color: base.colorScheme.outlineVariant),
          ),
          labelStyle: TextStyle(color: base.colorScheme.onSurface),
          color: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? base.colorScheme.primaryContainer
                : const Color(0xFFF0F4F3),
          ),
        ),

        // Divider
        dividerTheme: DividerThemeData(
          color: Colors.grey.shade300,
          space: 24,
          thickness: 1,
        ),

        // Navigation
        navigationBarTheme: NavigationBarThemeData(
          height: 68,
          indicatorColor: base.colorScheme.primaryContainer.withOpacity(0.6),
          backgroundColor: Colors.white,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),

        // Snackbars
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          elevation: 1,
          backgroundColor: const Color(0xFF24312E),
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        // Bottom sheets
        bottomSheetTheme: BottomSheetThemeData(
          elevation: 2,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),

        // Dialogs
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        // Icon theme
        iconTheme: IconThemeData(color: const Color(0xFF3A4B47)),
      ),
      home: FutureBuilder<bool>(
        future: ApiService().tryAutoLogin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // After the initial check, the Consumer takes over for live updates.
          return Consumer<ApiService>(
            builder: (context, auth, child) {
              if (auth.isAuthenticated) {
                // No parameters are needed for HomeScreen.
                return const HomeScreen();
              } else {
                return const LoginScreen();
              }
            },
          );
        },
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}
