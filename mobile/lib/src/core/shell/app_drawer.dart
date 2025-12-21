import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_store.dart';
import '../../l10n/app_localizations.dart';
import 'shell_page.dart';

class AppDrawer extends StatelessWidget {
  final ShellPage current;
  final ValueChanged<ShellPage> onSelect;

  const AppDrawer({super.key, required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    Widget tile({
      required ShellPage page,
      required IconData icon,
      required String label,
    }) {
      final selected = current == page;
      return ListTile(
        leading: Icon(icon),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        selected: selected,
        selectedTileColor: theme.colorScheme.primary.withAlpha(18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: () => onSelect(page),
      );
    }

    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.dividerColor.withAlpha(40)),
                  color: theme.colorScheme.surface,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primary.withAlpha(25),
                      child: Icon(
                        Icons.local_hospital_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ✅ Brand ثابت لا يترجم
                          Text(
                            'CareSync',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t.hospitalFirst,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withAlpha(190),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              tile(
                page: ShellPage.home,
                icon: Icons.dashboard_rounded,
                label: t.nav_home,
              ),
              const SizedBox(height: 6),
              tile(
                page: ShellPage.staff,
                icon: Icons.groups_rounded,
                label: t.nav_staff,
              ),
              const SizedBox(height: 6),
              tile(
                page: ShellPage.account,
                icon: Icons.person_rounded,
                label: t.nav_account,
              ),

              const Spacer(),

              OutlinedButton.icon(
                onPressed: () => context.read<AuthStore>().logout(),
                icon: const Icon(Icons.logout_rounded),
                label: Text(t.account_logout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
