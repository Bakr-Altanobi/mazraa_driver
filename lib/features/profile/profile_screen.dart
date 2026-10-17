import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/app/app_settings.dart';
import 'package:mazraa_driver/core/constants/api_endpoints.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/theme/app_theme.dart';
import 'package:mazraa_driver/features/auth/auth_controller.dart';
import 'package:mazraa_driver/features/profile/driver_support_screen.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ar = isArabic(context);
    final confirmed = await confirmAction(
      context,
      title: ar ? 'تسجيل الخروج' : 'Sign out',
      message: ar
          ? 'سيتم حذف رموز الجلسة الآمنة من هذا الجهاز.'
          : 'Secure session tokens will be removed from this device.',
      confirmLabel: ar ? 'تسجيل الخروج' : 'Sign out',
      destructive: true,
    );
    if (confirmed) await ref.read(authControllerProvider).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = isArabic(context);
    final auth = ref.watch(authControllerProvider);
    final profile = auth.profile;
    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? 'حسابي' : 'Profile'),
        actions: [
          IconButton(
            tooltip: ar ? 'تحديث' : 'Refresh',
            onPressed: () => ref.read(authControllerProvider).refreshProfile(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
              children: [
                _ProfileHeader(profile: profile),
                const SizedBox(height: 18),
                SectionHeader(
                  title: ar ? 'بيانات السائق' : 'Driver details',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    children: [
                      _ProfileTile(
                        icon: Icons.alternate_email_rounded,
                        label: ar ? 'البريد الإلكتروني' : 'Email',
                        value: profile.email,
                      ),
                      const Divider(indent: 58, height: 1),
                      _ProfileTile(
                        icon: Icons.phone_outlined,
                        label: ar ? 'رقم الهاتف' : 'Phone',
                        value: profile.phone,
                      ),
                      const Divider(indent: 58, height: 1),
                      _ProfileTile(
                        icon: Icons.tag_rounded,
                        label: ar ? 'رمز السائق' : 'Driver code',
                        value:
                            profile.driverCode ??
                            (ar ? 'غير متاح' : 'Unavailable'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SectionHeader(
                  title: ar ? 'المركبة والاعتماد' : 'Vehicle & approval',
                  icon: Icons.local_shipping_outlined,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        title: ar ? 'نوع المركبة' : 'Vehicle',
                        value: _vehicleLabel(profile.vehicleType, ar),
                        icon: Icons.airport_shuttle_rounded,
                        accent: MazraaColors.orange,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: MetricCard(
                        title: ar ? 'حالة الاعتماد' : 'Approval',
                        value: profile.isApproved
                            ? (ar ? 'معتمد' : 'Approved')
                            : profile.approvalStatus,
                        icon: profile.isApproved
                            ? Icons.verified_rounded
                            : Icons.pending_actions_rounded,
                        accent: profile.isApproved
                            ? MazraaColors.success
                            : MazraaColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.settings_outlined),
                        title: Text(ar ? 'الإعدادات' : 'Settings'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/settings'),
                      ),
                      const Divider(indent: 58, height: 1),
                      ListTile(
                        leading: const Icon(Icons.grid_view_rounded),
                        title: Text(ar ? 'جميع خدمات السائق' : 'Driver services'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/driver-services'),
                      ),
                      const Divider(indent: 58, height: 1),
                      ListTile(
                        leading: const Icon(Icons.support_agent_rounded),
                        title: Text(ar ? 'المساعدة والدعم' : 'Help & support'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/support'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => _logout(context, ref),
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(ar ? 'تسجيل الخروج' : 'Sign out'),
                ),
              ],
            ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});
  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final image = profile.profileImageUrl;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [MazraaColors.forest, MazraaColors.forestDark],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white.withValues(alpha: .18),
            foregroundImage: image == null || image.isEmpty
                ? null
                : NetworkImage(image),
            child: image == null || image.isEmpty
                ? const Icon(
                    Icons.person_rounded,
                    size: 38,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 5),
                Text(
                  '${ar ? 'التقييم' : 'Rating'} ${profile.ratingAverage.toStringAsFixed(1)} (${profile.ratingCount})',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                StatusPill(
                  label: profile.isVerified
                      ? (ar ? 'هوية موثقة' : 'Verified')
                      : (ar ? 'بانتظار التحقق' : 'Verification pending'),
                  color: profile.isVerified
                      ? const Color(0xFFBDE8C9)
                      : const Color(0xFFFFD49E),
                  icon: profile.isVerified
                      ? Icons.verified_user_rounded
                      : Icons.schedule_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      subtitle: Text(
        value,
        textDirection: value.contains('@') ? TextDirection.ltr : null,
      ),
    );
  }
}

String _vehicleLabel(String value, bool ar) {
  if (!ar) return value;
  return switch (value.toLowerCase()) {
    'motorcycle' => 'دراجة',
    'car' => 'سيارة',
    'van' => 'فان',
    'truck' => 'شاحنة',
    _ => value,
  };
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final ar = isArabic(context);
    return Scaffold(
      appBar: AppBar(title: Text(ar ? 'الإعدادات' : 'Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
        children: [
          SectionHeader(
            title: ar ? 'اللغة' : 'Language',
            icon: Icons.language_rounded,
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'ar', label: Text('العربية')),
                  ButtonSegment(value: 'en', label: Text('English')),
                ],
                selected: {settings.locale.languageCode},
                onSelectionChanged: (value) =>
                    settings.setLocale(Locale(value.first)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SectionHeader(
            title: ar ? 'المظهر' : 'Appearance',
            icon: Icons.palette_outlined,
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.brightness_auto_rounded),
                    label: Text(ar ? 'تلقائي' : 'Auto'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode_outlined),
                    label: Text(ar ? 'فاتح' : 'Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode_outlined),
                    label: Text(ar ? 'داكن' : 'Dark'),
                  ),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (value) =>
                    settings.setThemeMode(value.first),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SectionHeader(
            title: ar ? 'الخرائط' : 'Maps',
            icon: Icons.map_outlined,
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: Icon(
                AppEnvironment.mapsEnabled
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                color: AppEnvironment.mapsEnabled
                    ? MazraaColors.success
                    : MazraaColors.warning,
              ),
              title: Text(
                AppEnvironment.mapsEnabled
                    ? (ar ? 'Google Maps مفعلة' : 'Google Maps enabled')
                    : (ar
                          ? 'Google Maps غير مهيأة'
                          : 'Google Maps not configured'),
              ),
              subtitle: Text(
                ar
                    ? 'تتم إدارة المفتاح خارج ملفات Dart عبر إعدادات البناء الآمنة.'
                    : 'The key is managed outside Dart through secure build configuration.',
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(ar ? 'الخصوصية' : 'Privacy'),
                  subtitle: Text(
                    ar
                        ? 'لا يتم تتبع الموقع خارج مهمة نشطة.'
                        : 'Location is not tracked outside an active mission.',
                  ),
                ),
                const Divider(indent: 58, height: 1),
                ListTile(
                  leading: const Icon(Icons.dns_outlined),
                  title: const Text('API'),
                  subtitle: const Text(
                    ApiEndpoints.baseUrl,
                    textDirection: TextDirection.ltr,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) => const DriverSupportScreen();
}
