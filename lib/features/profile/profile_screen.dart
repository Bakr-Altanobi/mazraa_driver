import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/app/app_settings.dart';
import 'package:mazraa_driver/core/constants/api_endpoints.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/theme/app_theme.dart';
import 'package:mazraa_driver/features/auth/auth_controller.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = ref.read(authControllerProvider);
      if (auth.isAuthenticated && auth.profile == null) {
        auth.refreshProfile();
      }
    });
  }

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
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final auth = ref.watch(authControllerProvider);
    final profile = auth.profile;
    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? 'حسابي' : 'Profile'),
        actions: [
          IconButton(
            tooltip: ar ? 'تحديث' : 'Refresh',
            onPressed: auth.isRefreshingProfile
                ? null
                : () => ref.read(authControllerProvider).refreshProfile(),
            icon: auth.isRefreshingProfile
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: profile == null
          ? auth.isRefreshingProfile
              ? const Center(child: CircularProgressIndicator(
                  key: Key('profileLoadingIndicator')))
              : ErrorState(
                  error: auth.profileError ??
                      (ar ? 'تعذر الحصول على بيانات حساب السائق. أعد المحاولة.'
                          : 'Your driver profile is not available. Try again.'),
                  onRetry: () => ref.read(authControllerProvider).refreshProfile(),
                )
          : RefreshIndicator(
              onRefresh: () => ref.read(authControllerProvider).refreshProfile(),
              child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
              children: [
                if (auth.profileError != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.cloud_off_outlined),
                      title: Text(ar
                          ? 'عرض آخر بيانات محفوظة؛ تعذر التحديث.'
                          : 'Showing last loaded data; refresh failed.'),
                      subtitle: Text(auth.profileError!),
                      trailing: IconButton(
                        tooltip: ar ? 'إعادة المحاولة' : 'Retry',
                        onPressed: () => ref.read(authControllerProvider).refreshProfile(),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ),
                  ),
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
                        leading: const Icon(Icons.upload_file_outlined),
                        title: Text(
                          ar ? 'رفع مستندات السائق' : 'Upload driver documents',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/upload-document'),
                      ),
                      const Divider(indent: 58, height: 1),
                      ListTile(
                        leading: const Icon(Icons.grid_view_rounded),
                        title: Text(ar ? 'كل خدمات السائق' : 'Driver services'),
                        subtitle: Text(
                          ar
                              ? 'الجدول، المركبة، المرتجعات، البلاغات والأرباح'
                              : 'Schedule, vehicle, returns, incidents and earnings',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/services'),
                      ),
                      const Divider(indent: 58, height: 1),
                      ListTile(
                        leading: const Icon(Icons.settings_outlined),
                        title: Text(ar ? 'الإعدادات' : 'Settings'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/settings'),
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
                for (final link in <String, String>{
                  '/tools/edit-profile': ar ? 'تعديل بياناتي' : 'Edit profile',
                  '/tools/avatar': ar ? 'الصورة الشخصية' : 'Profile photo',
                  '/tools/phone-change': ar
                      ? 'تغيير الهاتف والتحقق'
                      : 'Change phone & verify',
                  '/tools/preferences': ar
                      ? 'تفضيلات العمل'
                      : 'Work preferences',
                  '/tools/account-status': ar
                      ? 'حالة الاعتماد'
                      : 'Approval status',
                }.entries)
                  ListTile(
                    title: Text(link.value),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(link.key),
                  ),
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
            ),
    );
  }
}

/// The media service may return relative image paths from uploaded files.
String? _resolveProfileImage(String? raw) {
  final image = raw?.trim();
  if (image == null || image.isEmpty || image.startsWith('//')) return null;
  final uri = Uri.tryParse(image);
  if (uri == null) return null;
  if (uri.hasScheme) {
    return uri.scheme == 'https' || uri.scheme == 'http' ? image : null;
  }
  final base = Uri.tryParse(ApiEndpoints.baseUrl);
  return base?.resolve(image).toString();
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});
  final DriverProfile profile;

  @override
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    final image = _resolveProfileImage(profile.profileImageUrl);
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
            // Server uploads may return a relative /images/... path. The
            // fallback icon must remain visible when an image fetch fails.
            foregroundImage: image == null ? null : NetworkImage(image),
            child: const Icon(
              Icons.person_rounded,
              size: 38,
              color: Colors.white,
            ),
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
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(ar ? 'حول التطبيق والتراخيص' : 'About & licenses'),
            onTap: () => showLicensePage(
              context: context,
              applicationName: ar ? 'مزرعتي للسائق' : 'Mazraa Driver',
              applicationVersion: '1.1.0',
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
                    ? (ar
                          ? 'الخرائط التفاعلية مفعلة'
                          : 'Interactive maps enabled')
                    : (ar ? 'الخرائط غير مفعلة' : 'Maps not enabled'),
              ),
              subtitle: Text(
                ar
                    ? 'اختر OpenStreetMap أو Google من الخريطة؛ المسار يعتمد على خدمة الطرق.'
                    : 'Choose OpenStreetMap or Google on the map; road routes depend on the routing service.',
              ),
            ),
          ),
          const SizedBox(height: 20),
          for (final link in <String, String>{
            '/tools/notification-preferences': ar
                ? 'تفضيلات الإشعارات'
                : 'Notification preferences',
            '/tools/security': ar ? 'تغيير كلمة المرور' : 'Change password',
            '/tools/sessions': ar ? 'الأجهزة والجلسات' : 'Devices & sessions',
            '/tools/privacy': ar ? 'الخصوصية' : 'Privacy',
            '/tools/health': ar
                ? 'الأذونات والاتصال'
                : 'Permissions & connection',
            '/tools/delete-account': ar
                ? 'طلب حذف الحساب'
                : 'Request account deletion',
            '/tools/training': ar ? 'دليل السائق' : 'Driver guide',
          }.entries)
            ListTile(
              title: Text(link.value),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(link.key),
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
                        ? 'تتم مشاركة الموقع أثناء التوفر للعروض أو تفعيل تتبع شحنة، وتتوقف عند إيقاف المشاركة أو تسجيل الخروج.'
                        : 'Location is shared while available for offers or tracking a shipment, and stops when sharing is disabled or you sign out.',
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
  Widget build(BuildContext context) {
    final ar = isArabic(context);
    return Scaffold(
      appBar: AppBar(title: Text(ar ? 'المساعدة والدعم' : 'Help & support')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.support_agent_rounded,
                  size: 52,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  ar ? 'كيف يمكننا مساعدتك؟' : 'How can we help?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 7),
                Text(
                  ar
                      ? 'لا توجد واجهة تذاكر دعم في السيرفر الحالي. لم نعرض إرسالًا وهميًا، ويمكن للإدارة ربطه عند توفير Endpoint.'
                      : 'The current server has no support-ticket endpoint. No simulated submission is shown; it can be connected when an endpoint is available.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionHeader(
            title: ar ? 'أسئلة شائعة' : 'Frequently asked questions',
            icon: Icons.quiz_outlined,
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ExpansionTile(
                  title: Text(
                    ar
                        ? 'لماذا لا أستطيع تغيير حالة الاتصال؟'
                        : 'Why can’t I change online status?',
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Text(
                      ar
                          ? 'يحتاج ذلك إلى Endpoint خاص بحالة السائق، وهو غير موجود في نسخة السيرفر الحالية.'
                          : 'It requires a driver-status endpoint, which is absent from the current server.',
                    ),
                  ],
                ),
                const Divider(height: 1),
                ExpansionTile(
                  title: Text(
                    ar
                        ? 'لماذا لا يظهر المسار على الخريطة؟'
                        : 'Why is route guidance unavailable?',
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Text(
                      ar
                          ? 'يلزم مفتاح Google Maps مقيّد وخدمة Routes مفعّلة. يمكن دائمًا فتح الملاحة الخارجية عند توفر إحداثيات الوجهة.'
                          : 'A restricted Google Maps key and Routes service are required. External navigation remains available when destination coordinates exist.',
                    ),
                  ],
                ),
                const Divider(height: 1),
                ExpansionTile(
                  title: Text(
                    ar
                        ? 'هل رصيد المحفظة هو أرباح السائق؟'
                        : 'Is wallet balance the same as driver earnings?',
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Text(
                      ar
                          ? 'لا. المحفظة حساب مالي عام، والسيرفر لا يوفّر حاليًا كشف مستحقات سائق مستقل.'
                          : 'No. The wallet is a general financial account; the server does not expose a separate driver earnings ledger.',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.shield_outlined,
                color: MazraaColors.forest,
              ),
              title: Text(ar ? 'السلامة أولًا' : 'Safety first'),
              subtitle: Text(
                ar
                    ? 'لا تستخدم التطبيق أثناء القيادة. توقف في مكان آمن قبل تنفيذ أي إجراء.'
                    : 'Do not operate the app while driving. Stop safely before taking action.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
