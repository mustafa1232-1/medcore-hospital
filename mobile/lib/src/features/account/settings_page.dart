// ignore_for_file: unreachable_switch_default

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/settings/app_settings_store.dart';
import '../../l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettingsStore>();
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    final bool rgb = s.themeStyle == AppThemeStyle.rgbPulse;

    return Scaffold(
      appBar: AppBar(title: Text(t.settings_title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _HeaderCard(
            title: 'تحكم كامل بالتجربة',
            subtitle: rgb
                ? 'RGB Pulse فعّال — واجهة نابضة وحيوية'
                : 'اختر المظهر واللغة وسهولة الوصول',
          ),
          const SizedBox(height: 12),

          _SectionTitle(t.settings_appearance),
          _Card(
            child: Column(
              children: [
                _ThemeModeTile(value: s.themeMode),
                const Divider(height: 1),
                _ThemeStyleTile(value: s.themeStyle),
                const Divider(height: 1),
                ListTile(
                  title: Text(t.settings_accentSeed),
                  subtitle: Text(
                    rgb
                        ? t.settings_accentSeed_disabled_rgb
                        : t.settings_accentSeed_subtitle,
                  ),
                  trailing: _ColorDot(color: s.accentSeed),
                  onTap: rgb ? null : () => _pickAccent(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          _SectionTitle(t.settings_language),
          _Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(t.settings_appLanguage),
                  subtitle: Text(_localeLabel(t, s.locale)),
                  trailing: const Icon(Icons.language_rounded),
                  onTap: () => _pickLocale(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          _SectionTitle(t.settings_accessibility),
          _Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(t.settings_reduceMotion),
                  subtitle: Text(t.settings_reduceMotion_sub),
                  value: s.reduceMotion,
                  onChanged: (v) => s.setReduceMotion(v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(t.settings_compactUi),
                  subtitle: Text(t.settings_compactUi_sub),
                  value: s.compactUi,
                  onChanged: (v) => s.setCompactUi(v),
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(t.settings_textSize),
                  subtitle: Text('${(s.textScale * 100).round()}%'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Slider(
                    min: 0.85,
                    max: 1.35,
                    divisions: 10,
                    value: s.textScale,
                    onChanged: (v) => s.setTextScale(v),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          _SectionTitle(t.settings_experience),
          _Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(t.settings_haptics),
                  subtitle: Text(t.settings_haptics_sub),
                  value: s.haptics,
                  onChanged: (v) => s.setHaptics(v),
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(t.settings_about),
                  subtitle: Text('${t.appName} — ${t.hospitalFirst}'),
                  trailing: const Icon(Icons.info_outline_rounded),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: t.appName,
                    applicationVersion: '1.0.0',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withAlpha(40)),
              color: theme.colorScheme.surface,
            ),
            child: Text(
              'إذا لم تتغير اللغة، تأكد أن MaterialApp مرتبط بـ settings.locale وأنك تعمل Hot Restart.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  static String _localeLabel(AppLocalizations t, Locale? locale) {
    if (locale == null) return t.settings_lang_system;
    return locale.languageCode == 'ar'
        ? t.settings_lang_ar
        : t.settings_lang_en;
  }

  Future<void> _pickAccent(BuildContext context) async {
    final s = context.read<AppSettingsStore>();
    final colors = const [
      Color(0xFF1976D2),
      Color(0xFF0F766E),
      Color(0xFF2E7D32),
      Color(0xFFC62828),
      Color(0xFF6A1B9A),
      Color(0xFFF57C00),
    ];

    final picked = await showModalBottomSheet<Color>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            runSpacing: 10,
            spacing: 10,
            children: colors
                .map(
                  (c) => InkWell(
                    onTap: () => Navigator.pop(ctx, c),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(ctx).dividerColor.withAlpha(60),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );

    if (picked != null) await s.setAccentSeed(picked);
  }

  Future<void> _pickLocale(BuildContext context) async {
    final s = context.read<AppSettingsStore>();
    final t = AppLocalizations.of(context);

    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.settings_suggest_rounded),
              title: Text(t.settings_lang_system),
              onTap: () => Navigator.pop(ctx, 'system'),
            ),
            ListTile(
              leading: const Icon(Icons.translate_rounded),
              title: Text(t.settings_lang_ar),
              onTap: () => Navigator.pop(ctx, 'ar'),
            ),
            ListTile(
              leading: const Icon(Icons.translate_rounded),
              title: Text(t.settings_lang_en),
              onTap: () => Navigator.pop(ctx, 'en'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (picked == null) return;

    if (picked == 'system') {
      await s.setLocale(null);
    } else {
      await s.setLocale(Locale(picked));
    }
  }
}

class _HeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeaderCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettingsStore>();
    final theme = Theme.of(context);

    final bool rgb = s.themeStyle == AppThemeStyle.rgbPulse;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: rgb
            ? LinearGradient(
                colors: [
                  s.rgbSeed.withAlpha(200),
                  theme.colorScheme.primary.withAlpha(90),
                  theme.colorScheme.surface,
                ],
              )
            : LinearGradient(
                colors: [
                  theme.colorScheme.primary.withAlpha(26),
                  theme.colorScheme.surface,
                ],
              ),
        border: Border.all(color: theme.dividerColor.withAlpha(40)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primary.withAlpha(30),
            child: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.dividerColor.withAlpha(40)),
      ),
      child: child,
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  final ThemeMode value;
  const _ThemeModeTile({required this.value});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppSettingsStore>();
    final t = AppLocalizations.of(context);

    String label;
    switch (value) {
      case ThemeMode.light:
        label = t.settings_themeMode_light;
        break;
      case ThemeMode.dark:
        label = t.settings_themeMode_dark;
        break;
      case ThemeMode.system:
      default:
        label = t.settings_themeMode_system;
        break;
    }

    return ListTile(
      title: Text(t.settings_themeMode),
      subtitle: Text(label),
      trailing: const Icon(Icons.brightness_6_rounded),
      onTap: () async {
        final picked = await showModalBottomSheet<ThemeMode>(
          context: context,
          showDragHandle: true,
          builder: (ctx) {
            final tt = AppLocalizations.of(ctx);
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(tt.settings_themeMode_system),
                    onTap: () => Navigator.pop(ctx, ThemeMode.system),
                  ),
                  ListTile(
                    title: Text(tt.settings_themeMode_light),
                    onTap: () => Navigator.pop(ctx, ThemeMode.light),
                  ),
                  ListTile(
                    title: Text(tt.settings_themeMode_dark),
                    onTap: () => Navigator.pop(ctx, ThemeMode.dark),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );

        if (picked != null) await s.setThemeMode(picked);
      },
    );
  }
}

class _ThemeStyleTile extends StatelessWidget {
  final AppThemeStyle value;
  const _ThemeStyleTile({required this.value});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppSettingsStore>();
    final t = AppLocalizations.of(context);

    String label;
    switch (value) {
      case AppThemeStyle.neon:
        label = t.settings_themeStyle_neon;
        break;
      case AppThemeStyle.rgbPulse:
        label = t.settings_themeStyle_rgbPulse;
        break;
      case AppThemeStyle.classic:
      default:
        label = t.settings_themeStyle_classic;
        break;
    }

    return ListTile(
      title: Text(t.settings_themeStyle),
      subtitle: Text(label),
      trailing: const Icon(Icons.palette_outlined),
      onTap: () async {
        final picked = await showModalBottomSheet<AppThemeStyle>(
          context: context,
          showDragHandle: true,
          builder: (ctx) {
            final tt = AppLocalizations.of(ctx);
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(tt.settings_themeStyle_classic),
                    onTap: () => Navigator.pop(ctx, AppThemeStyle.classic),
                  ),
                  ListTile(
                    title: Text(tt.settings_themeStyle_neon),
                    onTap: () => Navigator.pop(ctx, AppThemeStyle.neon),
                  ),
                  ListTile(
                    title: Text(tt.settings_themeStyle_rgbPulse),
                    onTap: () => Navigator.pop(ctx, AppThemeStyle.rgbPulse),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );

        if (picked != null) await s.setThemeStyle(picked);
      },
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).dividerColor.withAlpha(60)),
      ),
    );
  }
}
