import 'package:flutter/material.dart';

/// App-wide current locale, held outside any single screen's state so a language
/// picker dropped into one module's settings screen can change what every other
/// screen renders in, without those screens needing to know about each other.
///
/// `null` means "follow the device's locale" (falls back to English if the
/// device locale isn't one of [AppLocaleController.supported]) — this is the
/// default so the app doesn't silently force English on a Bodo or Assamese
/// device before anyone has touched the language picker.
class AppLocaleController extends ValueNotifier<Locale?> {
  AppLocaleController._() : super(null);

  static final AppLocaleController instance = AppLocaleController._();

  static const supported = [
    Locale('en'),
    Locale('as'),
    Locale('brx'),
    Locale('mni'),
  ];

  void setLocale(Locale? locale) => value = locale;
}
