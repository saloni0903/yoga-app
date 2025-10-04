// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get welcomeBack => 'वापसी पर स्वागत है';

  @override
  String get loginScreenTitle => 'अपनी योग यात्रा जारी रखें';

  @override
  String get emailLabel => 'ईमेल';

  @override
  String get passwordLabel => 'पासवर्ड';

  @override
  String get loginButton => 'लॉग इन करें';

  @override
  String get accountPending => 'खाता लंबित है';

  @override
  String get status => 'स्थिति';

  @override
  String get accountPendingMessage =>
      'आपका प्रशिक्षक खाता आयुष विभाग से अनुमोदन की प्रतीक्षा कर रहा है। आपके खाते को मंजूरी मिलने के बाद आप समूह बना और प्रबंधित कर पाएंगे।';

  @override
  String get myGroups => 'मेरे समूह';

  @override
  String get newGroupButton => 'नया समूह';

  @override
  String get noGroupsFound =>
      'कोई समूह नहीं मिला। एक बनाने के लिए + पर टैप करें!';
}
