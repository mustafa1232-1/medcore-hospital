import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../src/core/auth/auth_store.dart';
import '../../../src/core/settings/app_settings_store.dart';
import '../../../src/l10n/app_localizations.dart';

class V2SettingsPage extends StatelessWidget {
  const V2SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final settings = context.watch<AppSettingsStore>();

    return Scaffold(
      appBar: AppBar(title: Text(t.settings_title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        children: [
          _card(
            context,
            title: t.settings_appearance,
            child: Column(
              children: [
                _themeTile(context, settings),
                const SizedBox(height: 10),
                _textScaleTile(context, settings),
              ],
            ),
          ),
          const SizedBox(height: 12),

          _card(
            context,
            title: t.settings_language,
            child: _languageTile(context, settings),
          ),
          const SizedBox(height: 12),

          _card(
            context,
            title: t.account_title,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: Text(t.account_logout),
                  onTap: () => context.read<AuthStore>().logout(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withAlpha(40)),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _themeTile(BuildContext context, AppSettingsStore s) {
    final t = AppLocalizations.of(context);

    return InputDecorator(
      decoration: InputDecoration(
        labelText: t.settings_themeMode,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ThemeMode>(
          value: s.themeMode,
          isExpanded: true,
          items: [
            DropdownMenuItem(
              value: ThemeMode.system,
              child: Text(t.settings_themeMode_system),
            ),
            DropdownMenuItem(
              value: ThemeMode.light,
              child: Text(t.settings_themeMode_light),
            ),
            DropdownMenuItem(
              value: ThemeMode.dark,
              child: Text(t.settings_themeMode_dark),
            ),
          ],
          onChanged: (v) {
            if (v != null) s.setThemeMode(v);
          },
        ),
      ),
    );
  }

  Widget _languageTile(BuildContext context, AppSettingsStore s) {
    final t = AppLocalizations.of(context);

    return InputDecorator(
      decoration: InputDecoration(
        labelText: t.settings_appLanguage,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Locale?>(
          value: s.locale, // null يعني system حسب تطبيقك
          isExpanded: true,
          items: [
            DropdownMenuItem(value: null, child: Text(t.settings_lang_system)),
            const DropdownMenuItem(value: Locale('ar'), child: Text('العربية')),
            const DropdownMenuItem(value: Locale('en'), child: Text('English')),
          ],
          onChanged: (v) => s.setLocale(v),
        ),
      ),
    );
  }

  Widget _textScaleTile(BuildContext context, AppSettingsStore s) {
    final t = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.settings_textSize,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        Slider(
          value: s.textScale,
          min: 0.9,
          max: 1.3,
          divisions: 4,
          label: s.textScale.toStringAsFixed(1),
          onChanged: (v) => s.setTextScale(v),
        ),
      ],
    );
  }
}
