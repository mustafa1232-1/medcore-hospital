import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_store.dart';
import '../../l10n/app_localizations.dart';
import 'users_api_service.dart';
import 'create_user_page.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  final _qCtrl = TextEditingController();

  bool? _active; // null = all
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthStore>();
      if (auth.isReady && auth.isAuthenticated) {
        _load();
      } else {
        setState(() {
          _loading = false;
          _error = 'Unauthorized';
        });
      }
    });
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final users = await UsersApiService.listUsers(
        q: _qCtrl.text,
        active: _active,
      );
      if (!mounted) return;
      setState(() => _users = users);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = dioMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> u, AppLocalizations t) async {
    final id = u['id']?.toString() ?? '';
    final isActive = u['isActive'] == true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isActive ? t.staff_disable_user_q : t.staff_enable_user_q),
        content: Text(
          isActive ? t.staff_disable_user_desc : t.staff_enable_user_desc,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.common_confirm),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await UsersApiService.setActive(userId: id, isActive: !isActive);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(dioMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.staff_manage_title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreateUserPage()),
                  );
                  await _load();
                },
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: Text(t.staff_add_user),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _Filters(
            qCtrl: _qCtrl,
            active: _active,
            onActiveChanged: (v) => setState(() => _active = v),
            onSearch: _load,
          ),

          const SizedBox(height: 12),

          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 30),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _ErrorBox(message: _error!, onRetry: _load)
          else
            _UsersList(
              users: _users,
              onToggleActive: (u) => _toggleActive(u, t),
            ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final TextEditingController qCtrl;
  final bool? active;
  final ValueChanged<bool?> onActiveChanged;
  final VoidCallback onSearch;

  const _Filters({
    required this.qCtrl,
    required this.active,
    required this.onActiveChanged,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.dividerColor.withAlpha(40)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              controller: qCtrl,
              decoration: InputDecoration(
                labelText: t.staff_search_hint,
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onSubmitted: (_) => onSearch(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '${t.staff_status}: ',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 8),
                DropdownButton<bool?>(
                  value: active,
                  items: [
                    DropdownMenuItem(value: null, child: Text(t.common_all)),
                    DropdownMenuItem(value: true, child: Text(t.common_active)),
                    DropdownMenuItem(
                      value: false,
                      child: Text(t.common_inactive),
                    ),
                  ],
                  onChanged: onActiveChanged,
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: onSearch,
                  icon: const Icon(Icons.tune_rounded),
                  label: Text(t.common_apply),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UsersList extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final void Function(Map<String, dynamic>) onToggleActive;

  const _UsersList({required this.users, required this.onToggleActive});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Center(child: Text(t.staff_noResults)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (_, i) {
        final u = users[i];
        return _UserTile(user: u, onToggleActive: onToggleActive);
      },
    );
  }
}

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final void Function(Map<String, dynamic>) onToggleActive;

  const _UserTile({required this.user, required this.onToggleActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    final fullName = (user['fullName'] ?? '-').toString();
    final email = user['email']?.toString();
    final phone = user['phone']?.toString();
    final isActive = user['isActive'] == true;
    final roles =
        (user['roles'] as List?)?.map((e) => e.toString()).toList() ?? const [];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.dividerColor.withAlpha(40)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isActive
                      ? theme.colorScheme.primary.withAlpha(35)
                      : theme.colorScheme.error.withAlpha(25),
                  child: Icon(
                    Icons.person_rounded,
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email ?? phone ?? '-',
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color?.withAlpha(
                            190,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: isActive
                        ? theme.colorScheme.secondary.withAlpha(30)
                        : theme.colorScheme.error.withAlpha(20),
                  ),
                  child: Text(
                    isActive ? t.user_active : t.user_inactive,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),

            if (roles.isNotEmpty) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: roles
                      .map(
                        (r) => Chip(
                          label: Text(
                            r,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],

            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => onToggleActive(user),
              icon: Icon(
                isActive
                    ? Icons.pause_circle_rounded
                    : Icons.play_circle_rounded,
              ),
              label: Text(isActive ? t.user_disable : t.user_enable),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.error.withAlpha(70)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              message,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(t.common_retry),
            ),
          ],
        ),
      ),
    );
  }
}
