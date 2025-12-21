import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const String _brandName = 'CareSync';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    Color a(Color c, int alpha) => c.withAlpha(alpha);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            a(theme.colorScheme.primary, 18),
            a(theme.colorScheme.tertiary, 14),
            Colors.transparent,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _HeroCard(
            // ✅ Brand ثابت (لا يتغير مع اللغة)
            title: _brandName,
            subtitle: t.hospitalFirst,
            leftIcon: Icons.dashboard_rounded,
          ),
          const SizedBox(height: 12),

          Text(
            t.nav_home,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),

          _QuickActionsGrid(
            actions: [
              _QuickAction(
                title: 'New patient',
                subtitle: 'Register patient',
                icon: Icons.person_add_alt_1_rounded,
                onTap: () => _toast(context, 'Soon'),
              ),
              _QuickAction(
                title: 'Visit / Admit',
                subtitle: 'Open file',
                icon: Icons.assignment_rounded,
                onTap: () => _toast(context, 'Soon'),
              ),
              _QuickAction(
                title: 'Lab order',
                subtitle: 'Tests',
                icon: Icons.science_rounded,
                onTap: () => _toast(context, 'Soon'),
              ),
              _QuickAction(
                title: 'Prescription',
                subtitle: 'Dispense',
                icon: Icons.medication_rounded,
                onTap: () => _toast(context, 'Soon'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            'Modules',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),

          _ModuleList(
            items: [
              _ModuleItem(
                title: t.staff_title,
                subtitle: 'Users, roles, permissions',
                icon: Icons.admin_panel_settings_rounded,
                onTap: () => _toast(context, t.nav_staff),
              ),
              _ModuleItem(
                title: 'Lab',
                subtitle: 'Orders & results',
                icon: Icons.biotech_rounded,
                onTap: () => _toast(context, 'Soon'),
              ),
              _ModuleItem(
                title: 'Pharmacy',
                subtitle: 'Prescriptions & dispensing',
                icon: Icons.local_pharmacy_rounded,
                onTap: () => _toast(context, 'Soon'),
              ),
              _ModuleItem(
                title: 'Inventory',
                subtitle: 'Items, stock, expiry',
                icon: Icons.warehouse_rounded,
                onTap: () => _toast(context, 'Soon'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData leftIcon;

  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.leftIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color a(Color c, int alpha) => c.withAlpha(alpha);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: theme.dividerColor.withAlpha(40)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    a(theme.colorScheme.primary, 220),
                    a(theme.colorScheme.tertiary, 190),
                  ],
                ),
              ),
              child: Icon(leftIcon, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withAlpha(190),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final List<_QuickAction> actions;
  const _QuickActionsGrid({required this.actions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color a(Color c, int alpha) => c.withAlpha(alpha);

    return GridView.builder(
      itemCount: actions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (_, i) {
        final action = actions[i];
        return InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.dividerColor.withAlpha(40)),
              color: a(theme.colorScheme.surfaceContainerHighest, 120),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: a(theme.colorScheme.primary, 30),
                    border: Border.all(color: a(theme.colorScheme.primary, 55)),
                  ),
                  child: Icon(action.icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.title,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        action.subtitle,
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color?.withAlpha(
                            190,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

class _ModuleList extends StatelessWidget {
  final List<_ModuleItem> items;
  const _ModuleList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ModuleTile(item: m),
            ),
          )
          .toList(),
    );
  }
}

class _ModuleItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  _ModuleItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

class _ModuleTile extends StatelessWidget {
  final _ModuleItem item;
  const _ModuleTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.dividerColor.withAlpha(40)),
          color: theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.tertiary.withAlpha(30),
                border: Border.all(
                  color: theme.colorScheme.tertiary.withAlpha(55),
                ),
              ),
              child: Icon(item.icon, color: theme.colorScheme.tertiary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withAlpha(190),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.iconTheme.color?.withAlpha(160),
            ),
          ],
        ),
      ),
    );
  }
}
