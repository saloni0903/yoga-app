import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoga_app/api_service.dart';
import 'package:yoga_app/theme_provider.dart';
import 'package:yoga_app/screens/about_screen.dart';
import 'package:yoga_app/screens/profile/profile_screen.dart';
import 'package:yoga_app/generated/app_localizations.dart';
import 'package:yoga_app/providers/language_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.myProfile),
            subtitle: Text(l10n.editProfile),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: Text(l10n.darkMode),
            trailing: Switch(
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (value) {
                themeProvider.toggleTheme(value);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text(l10n.language), 
            subtitle: Text(l10n.languageName), 
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Simple language switcher
              showDialog(context: context, builder: (ctx) => AlertDialog(
                title: Text(l10n.selectLanguage),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(title: const Text('English'), onTap: () {
                      languageProvider.setLocale(const Locale('en'));
                      Navigator.of(ctx).pop();
                    }),
                    ListTile(title: const Text('हिंदी'), onTap: () {
                      languageProvider.setLocale(const Locale('hi'));
                      Navigator.of(ctx).pop();
                    }),
                  ],
                ),
              ));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.aboutApp),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red.shade700),
            title: Text(l10n.logout, style: TextStyle(color: Colors.red.shade700)),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.confirmLogout),
                  content: Text(l10n.areYouSureLogout),
                  actions: [
                    TextButton(
                      child: Text(l10n.cancel),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    FilledButton(
                      child: Text(l10n.logout),
                      onPressed: () {
                        apiService.logout();
                        Navigator.of(context, rootNavigator: true)
                            .pushNamedAndRemoveUntil('/login', (route) => false);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}