// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_store.dart';
import '../../l10n/app_localizations.dart';
import 'settings_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  File? _pickedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (x == null) return;
    if (!mounted) return;
    setState(() => _pickedImage = File(x.path));
  }

  Future<void> _copy(String text) async {
    final t = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.common_confirm)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    final auth = context.watch<AuthStore>();
    final user = auth.user;

    if (user == null) return Center(child: Text(t.account_noData));

    final fullName = (user['fullName'] ?? '-').toString();
    final email = (user['email'] ?? '').toString();
    final phone = (user['phone'] ?? '').toString();

    // backend fields
    final tenantId = (user['tenantId'] ?? '').toString();
    final tenantCode = (user['tenantCode'] ?? '')
        .toString(); // if you later return it
    final staffCode = (user['staffCode'] ?? '').toString(); // NEW
    final userId = (user['id'] ?? '')
        .toString(); // internal uuid (we will not show unless needed)

    final roles =
        (user['roles'] as List?)?.map((e) => e.toString()).toList() ?? const [];

    // show facility code:
    final facilityCodeToShow = tenantCode.isNotEmpty ? tenantCode : tenantId;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: theme.dividerColor.withAlpha(40)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: theme.colorScheme.primary.withAlpha(35),
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : null,
                      child: _pickedImage == null
                          ? Icon(
                              Icons.person_rounded,
                              size: 34,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: theme.colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t.account_subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withAlpha(
                            190,
                          ),
                        ),
                      ),
                      if (roles.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: roles
                              .map(
                                (r) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: theme.colorScheme.primary.withAlpha(
                                      16,
                                    ),
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withAlpha(45),
                                    ),
                                  ),
                                  child: Text(
                                    r,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        _InfoCard(
          title: t.account_info,
          items: [
            if (email.isNotEmpty)
              _kvRow('Email', email, onCopy: () => _copy(email)),
            if (phone.isNotEmpty)
              _kvRow('Phone', phone, onCopy: () => _copy(phone)),

            // ✅ clearer than "Tenant"
            _kvRow(
              t.facility_code,
              facilityCodeToShow,
              onCopy: () => _copy(facilityCodeToShow),
            ),

            // ✅ staff code for users
            if (staffCode.isNotEmpty)
              _kvRow(t.staff_id, staffCode, onCopy: () => _copy(staffCode))
            else if (userId.isNotEmpty)
              _kvRow(t.staff_id, userId, onCopy: () => _copy(userId)),
          ],
        ),

        const SizedBox(height: 12),

        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: theme.dividerColor.withAlpha(40)),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.settings_rounded),
                title: Text(t.settings_title),
                subtitle: Text(
                  '${t.settings_appearance} • ${t.settings_language}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: Text(t.account_logout),
                onTap: () => context.read<AuthStore>().logout(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _kvRow(String k, String v, {VoidCallback? onCopy}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(k, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          Expanded(child: Text(v)),
          if (onCopy != null)
            IconButton(
              tooltip: 'Copy',
              onPressed: onCopy,
              icon: const Icon(Icons.copy_rounded, size: 18),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget>? items;

  const _InfoCard({required this.title, this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.dividerColor.withAlpha(40)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            if (items != null) ...items!,
          ],
        ),
      ),
    );
  }
}
