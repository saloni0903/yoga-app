// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get loginScreenTitle => 'Continue your yoga journey';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginButton => 'Login';

  @override
  String get accountPending => 'Account Pending';

  @override
  String get status => 'Status';

  @override
  String get accountPendingMessage =>
      'Your instructor account is awaiting approval from the Aayush department. You will be able to create and manage groups once your account is approved.';

  @override
  String get myGroups => 'My Groups';

  @override
  String get newGroupButton => 'New Group';

  @override
  String get noGroupsFound => 'No groups found. Tap + to create one!';
}
