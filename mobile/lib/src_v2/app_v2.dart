// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../src/core/auth/auth_store.dart';
import '../src/core/settings/app_settings_store.dart';
import '../src/core/settings/app_theme.dart';
import '../src/l10n/app_localizations.dart';

import 'core/shell/v2_shell.dart';

class MedcoreAppV2 extends StatelessWidget {
  const MedcoreAppV2({super.key});

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
            title: 'CareSync',

            locale: settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

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

            themeMode: settings.themeMode,
            theme: AppTheme.build(settings, Brightness.light),
            darkTheme: AppTheme.build(settings, Brightness.dark),

            home: const V2Shell(),
          );
        },
      ),
    );
  }
}
