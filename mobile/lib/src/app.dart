// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/auth/auth_store.dart';
import 'core/settings/app_settings_store.dart';
import 'core/settings/app_theme.dart';

import 'l10n/app_localizations.dart';

// ✅ Shell
import 'core/shell/app_shell.dart';

class MedcoreApp extends StatelessWidget {
  const MedcoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthStore()..bootstrap()),
        ChangeNotifierProvider(create: (_) => AppSettingsStore()..load()),
      ],
      child: Consumer<AppSettingsStore>(
        builder: (context, settings, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,

            // ✅ Brand ثابت لا يتغير
            title: 'CareSync',

            // ✅ Localization (النصوص فقط)
            locale: settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // ✅ لا نستخدم onGenerateTitle حتى لا يتغير اسم التطبيق

            // ✅ Force LTR + apply text scale globally
            builder: (context, child) {
              return Directionality(
                textDirection: TextDirection.ltr,
                child: MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaleFactor: settings.textScale),
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },

            // ✅ Theme من إعداداتك
            themeMode: settings.themeMode,
            theme: AppTheme.build(settings, Brightness.light),
            darkTheme: AppTheme.build(settings, Brightness.dark),

            // ✅ Root Shell
            home: const AppShell(),
          );
        },
      ),
    );
  }
}
