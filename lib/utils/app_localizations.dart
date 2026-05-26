import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const _labels = <String, Map<String, String>>{
    'en': {
      'dashboard': 'Dashboard',
      'purchase': 'Purchase',
      'sales': 'Sales',
      'stock': 'Stock',
      'reports': 'Reports',
      'addExpense': 'Add Expense',
      'todayOverview': 'Today Overview',
      'quickEntry': 'Quick Entry',
      'businessReports': 'Business Reports',
    },
    'ta': {
      'dashboard': 'முகப்பு',
      'purchase': 'கொள்முதல்',
      'sales': 'விற்பனை',
      'stock': 'கையிருப்பு',
      'reports': 'அறிக்கைகள்',
      'addExpense': 'செலவு சேர்',
      'todayOverview': 'இன்றைய சுருக்கம்',
      'quickEntry': 'விரைவு பதிவு',
      'businessReports': 'வணிக அறிக்கைகள்',
    },
  };

  String text(String key) =>
      _labels[locale.languageCode]?[key] ?? _labels['en']![key] ?? key;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ta'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension LocalizationContext on BuildContext {
  String tr(String key) => AppLocalizations.of(this).text(key);
}
