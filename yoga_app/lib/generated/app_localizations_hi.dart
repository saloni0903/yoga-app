// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get welcomeBack => 'स्वागत है';

  @override
  String get loginScreenTitle => 'अपनी योग यात्रा जारी रखें';

  @override
  String get emailLabel => 'ईमेल';

  @override
  String get passwordLabel => 'पासवर्ड';

  @override
  String get loginButton => 'लॉग इन करें';

  @override
  String get newToApp => 'YES पर नए हैं?';

  @override
  String get registerNewAccount => 'एक नया खाता पंजीकृत करें';

  @override
  String get accountPending => 'खाता लंबित है';

  @override
  String get status => 'स्थिति';

  @override
  String get accountPendingMessage =>
      'आपका प्रशिक्षक खाता अनुमोदन की प्रतीक्षा कर रहा है। स्वीकृत होने के बाद आप समूह बना और प्रबंधित कर पाएंगे।';

  @override
  String get dashboard => 'डैशबोर्ड';

  @override
  String get myGroups => 'मेरे समूह';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get newGroupButton => 'नया समूह';

  @override
  String get noGroupsFoundInstructor => 'आपने अभी तक कोई समूह नहीं बनाया है।';

  @override
  String get searchPlaceholder => 'स्थान या समूह के नाम से खोजें';

  @override
  String get list => 'सूची';

  @override
  String get map => 'नक्शा';

  @override
  String get enterSearchTerm => 'समूह खोजने के लिए एक खोज शब्द दर्ज करें।';

  @override
  String get noGroupsFoundSearch =>
      'आपकी खोज से मेल खाने वाले कोई समूह नहीं मिले।';

  @override
  String get joinGroupButton => 'समूह में शामिल हों';

  @override
  String get myProfile => 'मेरी प्रोफाइल';

  @override
  String get editProfile => 'अपनी व्यक्तिगत जानकारी संपादित करें';

  @override
  String get darkMode => 'डार्क मोड';

  @override
  String get language => 'भाषा';

  @override
  String get languageName => 'हिन्दी';

  @override
  String get selectLanguage => 'भाषा चुने';

  @override
  String get aboutApp => 'ऐप के बारे में';

  @override
  String get logout => 'लॉग आउट';

  @override
  String get confirmLogout => 'लॉगआउट की पुष्टि करें';

  @override
  String get areYouSureLogout => 'क्या आप वाकई लॉग आउट करना चाहते हैं?';

  @override
  String get cancel => 'रद्द करें';
}
