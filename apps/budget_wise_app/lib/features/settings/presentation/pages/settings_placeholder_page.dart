import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../di/injection.dart';
import '../../../../domain/repositories/auth_repository.dart';
import '../../../../router/app_router.dart';

/// Full Settings / More screen
/// Only Appearance section is enabled; all others are disabled (coming soon)
class SettingsPlaceholderPage extends ConsumerWidget {
  const SettingsPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text('More', style: AppStyles.displayMedium),
            const SizedBox(height: 4),
            Text('Settings & preferences', style: AppStyles.bodySmall),
            const SizedBox(height: 24),

            // ── Appearance (ENABLED) ──────────────────────────────────
            _SectionCard(
              title: 'Appearance',
              children: [
                _ThemeOption(
                  icon: Icons.phone_android,
                  label: 'System default',
                  isSelected: themeMode == ThemeMode.system,
                  onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system),
                ),
                const _SectionDivider(),
                _ThemeOption(
                  icon: Icons.light_mode_outlined,
                  label: 'Light',
                  isSelected: themeMode == ThemeMode.light,
                  onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
                ),
                const _SectionDivider(),
                _ThemeOption(
                  icon: Icons.dark_mode_outlined,
                  label: 'Dark',
                  isSelected: themeMode == ThemeMode.dark,
                  onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── General (DISABLED) ────────────────────────────────────
            _SectionCard(
              title: 'General',
              enabled: false,
              children: const [
                _DisabledRow(icon: Icons.language, label: 'Language'),
                _SectionDivider(),
                _DisabledRow(icon: Icons.attach_money, label: 'Currency'),
                _SectionDivider(),
                _DisabledRow(icon: Icons.notifications_outlined, label: 'Notifications'),
              ],
            ),

            const SizedBox(height: 16),

            // ── Data & Privacy (DISABLED) ─────────────────────────────
            _SectionCard(
              title: 'Data & Privacy',
              enabled: false,
              children: const [
                _DisabledRow(icon: Icons.cloud_upload_outlined, label: 'Export data'),
                _SectionDivider(),
                _DisabledRow(icon: Icons.cloud_download_outlined, label: 'Import data'),
                _SectionDivider(),
                _DisabledRow(icon: Icons.delete_outline, label: 'Clear all data'),
              ],
            ),

            const SizedBox(height: 16),

            // ── Account ────────────────────────────────────────────
            _SectionCard(
              title: 'Account',
              children: [
                const _DisabledRow(icon: Icons.person_outline, label: 'Profile'),
                const _SectionDivider(),
                const _DisabledRow(icon: Icons.lock_outline, label: 'Change password'),
                const _SectionDivider(),
                _SignOutRow(onTap: () async {
                  final result = await getIt<AuthRepository>().logout();
                  if (!context.mounted) return;
                  result.fold(
                    (failure) => context.showSnackBar(failure.message, isError: true),
                    (_) => context.go(AppRoutes.login),
                  );
                }),
              ],
            ),

            const SizedBox(height: 16),

            // ── About (DISABLED) ──────────────────────────────────────
            _SectionCard(
              title: 'About',
              enabled: false,
              children: const [
                _DisabledRow(icon: Icons.info_outline, label: 'Version 1.0.0'),
                _SectionDivider(),
                _DisabledRow(icon: Icons.description_outlined, label: 'Terms of service'),
                _SectionDivider(),
                _DisabledRow(icon: Icons.shield_outlined, label: 'Privacy policy'),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool enabled;

  const _SectionCard({required this.title, required this.children, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Container(
        padding: const EdgeInsets.all(AppDimens.cardPadding),
        decoration: AppStyles.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: AppStyles.label),
                if (!enabled) ...[
                  const Spacer(),
                  Text('Coming soon', style: AppStyles.caption.copyWith(fontSize: 11)),
                ],
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();
  @override
  Widget build(BuildContext context) => const Divider(height: 1, color: AppColors.divider);
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppStyles.bodyMedium)),
            if (isSelected) const Icon(Icons.check, size: 20, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}

class _DisabledRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DisabledRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppStyles.bodyMedium)),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

class _SignOutRow extends StatelessWidget {
  final VoidCallback onTap;

  const _SignOutRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(Icons.logout, size: 20, color: AppColors.expense),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sign out',
                style: AppStyles.bodyMedium.copyWith(color: AppColors.expense),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
