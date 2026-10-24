import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mazraa_driver/core/network/api_exception.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/features/auth/auth_controller.dart';
import 'package:mazraa_driver/features/operations/driver_live_providers.dart';
import 'package:mazraa_driver/features/operations/driver_operations_widgets.dart';
import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';
import 'driver_forms.dart';
import 'driver_tool_catalog.dart';
import 'driver_workspace_repository.dart';
import 'driver_schedule_widgets.dart';
import 'driver_service_areas_screen.dart';
import 'driver_referral_links.dart';

String toolText(BuildContext c, String ar, String en) => isArabic(c) ? ar : en;
const _fields = <String, (String, String)>{
  'name': ('الاسم', 'Name'),
  'code': ('الرمز', 'Code'),
  'driverCode': ('رمز السائق', 'Driver code'),
  'phone': ('الهاتف', 'Phone'),
  'deviceName': ('الجهاز', 'Device'),
  'deviceType': ('نوع الجهاز', 'Device type'),
  'platform': ('النظام', 'Platform'),
  'ipAddress': ('عنوان الاتصال', 'IP address'),
  'emailVerified': ('البريد موثق', 'Email verified'),
  'phoneVerified': ('الهاتف موثق', 'Phone verified'),
  'registrationNumber': ('رقم التسجيل', 'Registration number'),
  'registrationExpiryDate': ('انتهاء التسجيل', 'Registration expiry'),
  'insuranceNumber': ('رقم التأمين', 'Insurance number'),
  'insuranceExpiryDate': ('انتهاء التأمين', 'Insurance expiry'),
  'email': ('البريد', 'Email'),
  'status': ('الحالة', 'Status'),
  'type': ('النوع', 'Type'),
  'vehicleType': ('نوع المركبة', 'Vehicle type'),
  'plateNumber': ('رقم اللوحة', 'Plate'),
  'make': ('الشركة', 'Make'),
  'model': ('الطراز', 'Model'),
  'year': ('سنة الصنع', 'Year'),
  'maxWeightKg': ('الحمولة القصوى كجم', 'Max weight (kg)'),
  'capacityKg': ('الحمولة كجم', 'Capacity (kg)'),
  'maxVolumeM3': ('الحجم الأقصى م³', 'Max volume (m³)'),
  'capacityM3': ('السعة م³', 'Capacity (m³)'),
  'isActive': ('مفعّل', 'Active'),
  'documentNumber': ('رقم المستند', 'Document number'),
  'expiresAt': ('ينتهي في', 'Expires'),
  'reviewNotes': ('ملاحظات المراجعة', 'Review notes'),
  'createdAt': ('تاريخ الإنشاء', 'Created'),
  'bankName': ('البنك', 'Bank'),
  'accountHolderName': ('صاحب الحساب', 'Account holder'),
  'iban': ('IBAN', 'IBAN'),
  'accountNumber': ('رقم الحساب', 'Account number'),
  'isVerified': ('موثّق', 'Verified'),
  'amount': ('المبلغ', 'Amount'),
  'currency': ('العملة', 'Currency'),
  'currencyCode': ('العملة', 'Currency'),
  'balanceAfter': ('الرصيد بعد الحركة', 'Balance after'),
  'description': ('الوصف', 'Description'),
  'notes': ('الملاحظات', 'Notes'),
  'title': ('العنوان', 'Title'),
  'category': ('الفئة', 'Category'),
  'isEmergency': ('عاجل', 'Urgent'),
  'providerReference': ('مرجع التحويل', 'Transfer reference'),
  'baseFee': ('الرسوم الأساسية', 'Base fee'),
  'perKmFee': ('رسوم الكيلومتر', 'Fee per km'),
  'minDeliveryFee': ('الحد الأدنى للرسوم', 'Minimum delivery fee'),
  'maxDeliveryFee': ('الحد الأعلى للرسوم', 'Maximum delivery fee'),
  'radiusKm': ('النطاق كلم', 'Radius (km)'),
  'requestedAt': ('تاريخ الطلب', 'Requested'),
  'processedAt': ('تاريخ المعالجة', 'Processed'),
  'startedAt': ('البداية', 'Started'),
  'endedAt': ('النهاية', 'Ended'),
  'completedShipments': ('الشحنات المكتملة', 'Completed deliveries'),
  'serviceAt': ('تاريخ الصيانة', 'Service date'),
  'odometerKm': ('العداد كلم', 'Odometer (km)'),
  'nextServiceAt': ('الصيانة التالية', 'Next service'),
  'nextServiceOdometerKm': ('العداد التالي', 'Next odometer'),
  'plannedDepartureAt': ('المغادرة المخططة', 'Planned departure'),
  'plannedArrivalAt': ('الوصول المخطط', 'Planned arrival'),
  'actualDepartureAt': ('المغادرة الفعلية', 'Actual departure'),
  'actualArrivalAt': ('الوصول الفعلي', 'Actual arrival'),
  'dropoffName': ('نقطة التسليم', 'Meeting point'),
  'dropoffLatitude': ('خط عرض التسليم', 'Dropoff latitude'),
  'dropoffLongitude': ('خط طول التسليم', 'Dropoff longitude'),
  'maxStops': ('عدد المحطات الأقصى', 'Max stops'),
  'totalWeightKg': ('الوزن كجم', 'Weight (kg)'),
  'totalVolumeM3': ('الحجم م³', 'Volume (m³)'),
  'targetShipments': ('الهدف من الشحنات', 'Target deliveries'),
  'rewardAmount': ('مكافأة الحافز', 'Reward'),
  'startsAt': ('من', 'From'),
  'endsAt': ('حتى', 'Until'),
  'returnRequestId': ('رقم المرتجع', 'Return request'),
  'shipmentId': ('رقم الشحنة', 'Shipment'),
  'orderId': ('رقم الطلب', 'Order'),
  'acceptedAt': ('تم القبول', 'Accepted'),
  'pickedUpAt': ('تم الاستلام', 'Picked up'),
  'returnedAt': ('تمت الإعادة', 'Returned'),
  'dayOfWeek': ('يوم الأسبوع', 'Weekday'),
  'startTime': ('بداية الفترة', 'Start time'),
  'endTime': ('نهاية الفترة', 'End time'),
  'ratingAverage': ('متوسط التقييم', 'Average rating'),
  'ratingCount': ('عدد التقييمات', 'Rating count'),
  'deliveryRating': ('تقييم التوصيل', 'Delivery rating'),
  'comment': ('التعليق', 'Comment'),
  'averageDeliveryRating': ('متوسط تقييم التوصيل', 'Average delivery rating'),
  'total': ('الإجمالي', 'Total'),
  'failedShipments': ('التسليم المتعذر', 'Failed deliveries'),
  'activeShipments': ('الشحنات النشطة', 'Active shipments'),
  'offerAcceptanceRate': ('نسبة قبول العروض %', 'Offer acceptance %'),
  'totalOffers': ('كل العروض', 'Total offers'),
  'acceptedOffers': ('العروض المقبولة', 'Accepted offers'),
  'approvalStatus': ('حالة الاعتماد', 'Approval status'),
  'operationalStatus': ('حالة العمل', 'Work status'),
  'isAcceptingOrders': ('استقبال الطلبات', 'Accepting orders'),
  'joinedAt': ('تاريخ الانضمام', 'Joined'),
  'approvedAt': ('تاريخ الاعتماد', 'Approved'),
  'suspendedAt': ('تاريخ الإيقاف', 'Suspended'),
  'suspensionReason': ('سبب الإيقاف', 'Suspension reason'),
  'maxActiveShipments': (
    'الشحنات المتزامنة القصوى',
    'Maximum active shipments',
  ),
  'pushNotifications': ('إشعارات الهاتف', 'Push notifications'),
  'emailNotifications': ('إشعارات البريد', 'Email notifications'),
  'smsNotifications': ('رسائل نصية', 'SMS notifications'),
  'marketingNotifications': ('إشعارات تسويقية', 'Marketing notifications'),
  'acceptScheduledTrips': ('رحلات مجدولة', 'Scheduled trips'),
  'acceptPrivateDeliveries': ('توصيل خاص', 'Private deliveries'),
  'acceptBatchDeliveries': ('عدة طلبات', 'Batch deliveries'),
  'isAvailableForOffers': ('استقبال العروض', 'Receive offers'),
  'offerRadiusKm': ('نطاق العروض كلم', 'Offer radius (km)'),
  'offerTimeoutSeconds': ('مهلة العرض ثانية', 'Offer timeout (seconds)'),
  'shareAnalytics': ('تحليلات الاستخدام', 'Usage analytics'),
  'profileVisible': ('إظهار الملف الشخصي', 'Profile visible'),
  'recipientName': ('اسم المستلم', 'Recipient'),
  'verificationReference': ('مرجع التحقق', 'Verification reference'),
  'temperatureCelsius': ('الحرارة مئوية', 'Temperature °C'),
  'pickupChecklistAvailable': (
    'قائمة الاستلام متاحة',
    'Pickup checklist available',
  ),
  'cashCustodyLedgerAvailable': ('عهدة النقد متاحة', 'Cash custody available'),
  'trafficAwareRoutesConfigured': (
    'خدمة مسارات الطرق',
    'Road routes configured',
  ),
  'privateFileUploadsConfigured': (
    'رفع الملفات الخاصة',
    'Private file uploads configured',
  ),
};

String _value(BuildContext c, String key, dynamic value) {
  if (value is bool)
    return toolText(c, value ? 'نعم' : 'لا', value ? 'Yes' : 'No');
  if (key == 'dayOfWeek')
    return [
      'الأحد / Sunday',
      'الاثنين / Monday',
      'الثلاثاء / Tuesday',
      'الأربعاء / Wednesday',
      'الخميس / Thursday',
      'الجمعة / Friday',
      'السبت / Saturday',
    ][int.tryParse('$value')?.clamp(0, 6) ?? 0];
  final enums = <String, Map<String, (String, String)>>{
    'approvalStatus': {
      '1': ('قيد المراجعة', 'Pending'),
      '2': ('معتمد', 'Approved'),
      '3': ('مرفوض', 'Rejected'),
      '4': ('موقوف', 'Suspended'),
    },
    'operationalStatus': {
      '1': ('غير متصل', 'Offline'),
      '2': ('متصل', 'Online'),
      '3': ('متاح', 'Available'),
      '4': ('مشغول', 'Busy'),
    },
    'vehicleType': {
      '0': ('سيارة', 'Car'),
      '1': ('دراجة', 'Bike'),
      '2': ('فان', 'Van'),
      '3': ('شاحنة', 'Truck'),
    },
  };
  final label = enums[key]?['$value'];
  if (label != null) return toolText(c, label.$1, label.$2);
  if (key.endsWith('At') || key.endsWith('Date')) {
    final d = DateTime.tryParse('$value')?.toLocal();
    if (d != null)
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${TimeOfDay.fromDateTime(d).format(c)}';
  }
  return '$value';
}

class DriverRecordFields extends StatelessWidget {
  const DriverRecordFields({required this.record, super.key});
  final Map<String, dynamic> record;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final entry in _fields.entries)
        if (record[entry.key] != null &&
            record[entry.key] is! Map &&
            record[entry.key] is! List)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  toolText(context, entry.value.$1, entry.value.$2),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SelectableText(_value(context, entry.key, record[entry.key])),
              ],
            ),
          ),
    ],
  );
}

class DriverToolScreen extends ConsumerStatefulWidget {
  const DriverToolScreen({required this.toolId, this.recordId, super.key});
  final String toolId;
  final int? recordId;
  @override
  ConsumerState<DriverToolScreen> createState() => _DriverToolScreenState();
}

class _DriverToolScreenState extends ConsumerState<DriverToolScreen> {
  bool _busy = false;
  DriverTool get tool => driverTool(widget.toolId);
  Future<void> _mutate(Future<void> Function() work) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final yes = await confirmAction(
        context,
        title: toolText(context, 'تأكيد الإجراء', 'Confirm action'),
        message: toolText(
          context,
          'تنفيذ هذا الإجراء على المهمة المحددة؟',
          'Perform this action on the selected record?',
        ),
        confirmLabel: toolText(context, 'تأكيد', 'Confirm'),
      );
      if (!yes || !mounted) return;
      await work();
      ref.invalidate(toolDataProvider(tool.id));
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(toolText(context, 'تم حفظ الإجراء', 'Action saved')),
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _form(dynamic payload) async {
    if (_busy || tool.form == null) return;
    setState(() => _busy = true);
    try {
      var initial = <String, dynamic>{};
      if ({
        'preferences',
        'notification-preferences',
        'privacy',
        'edit-profile',
      }.contains(tool.id))
        initial = recordMap(payload);
      if ({
        'preferences',
        'notification-preferences',
        'privacy',
      }.contains(tool.id)) {
        final fields = toolForms[tool.form!]!;
        if (fields.any((f) => !initial.containsKey(f.key)))
          throw StateError(
            'تعذر تحميل كل التفضيلات الحالية. حدّث الصفحة أولًا. / Current preferences are incomplete. Refresh first.',
          );
      }
      if (tool.id == 'phone-confirm')
        initial = {'phone': ref.read(phoneVerificationTargetProvider) ?? ''};
      if (tool.id == 'bank') {
        final rows = recordRows(payload);
        initial = rows.isEmpty
            ? {}
            : rows.firstWhere(
                (r) => r['isDefault'] == true,
                orElse: () => rows.first,
              );
      }
      if (tool.id == 'maintenance') {
        final vehicle = await ref
            .read(apiClientProvider)
            .get<dynamic>('api/Vehicles/my-current');
        final current = recordMap(vehicle);
        final id = current['id'] ?? recordMap(current['vehicle'])['id'];
        if (id == null)
          throw StateError('لا توجد مركبة مسندة / No assigned vehicle');
        initial = {'vehicleId': id};
      }
      if (!mounted) return;
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => DriverToolFormScreen(
            form: tool.form!,
            title: toolText(context, tool.ar, tool.en),
            initial: initial,
            pending: tool.pending,
          ),
        ),
      );
      if (result == true) {
        if (tool.id == 'security') {
          await ref.read(authControllerProvider).logout();
          return;
        }
        if (tool.id == 'phone-change' && mounted) {
          await context.push('/tools/phone-confirm');
          if (mounted) ref.invalidate(toolDataProvider(tool.id));
          return;
        }
        if (tool.id == 'phone-confirm') {
          ref.read(phoneVerificationTargetProvider.notifier).state = null;
          await ref.read(authControllerProvider).refreshProfile();
        }
        if (tool.id == 'edit-profile')
          await ref.read(authControllerProvider).refreshProfile();
        if (tool.id == 'bank') ref.invalidate(driverBankAccountsProvider);
        ref.invalidate(toolDataProvider(tool.id));
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                toolText(context, 'تم حفظ بياناتك', 'Your changes were saved'),
              ),
            ),
          );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _avatar(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (image == null) return;
      await ref
          .read(apiClientProvider)
          .uploadFile(
            'api/users/me/avatar',
            filePath: image.path,
            fileName: image.name,
            fields: const {},
          );
      ref.invalidate(toolDataProvider(tool.id));
      await ref.read(authControllerProvider).refreshProfile();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              toolText(context, 'تم تحديث الصورة', 'Profile photo updated'),
            ),
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(toolDataProvider(tool.id));
    final ar = isArabic(context);
    final canEdit =
        tool.form != null &&
        (tool.pending ||
            !{
              'preferences',
              'notification-preferences',
              'privacy',
              'edit-profile',
            }.contains(tool.id) ||
            data.hasValue);
    return Scaffold(
      key: Key('tool-${tool.id}'),
      appBar: AppBar(
        title: Text(ar ? tool.ar : tool.en),

      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // The coverage editor reads the catalog of available zones as well
          // as the driver's own selections. Refresh both together.
          if (tool.id == 'service-area') {
            ref.invalidate(availableDriverZonesProvider);
          }
          ref.invalidate(toolDataProvider(tool.id));
          try {
            await ref.read(toolDataProvider(tool.id).future);
          } catch (_) {
            // The inline error remains visible and swipe-to-retry must not
            // propagate provider failures to the Flutter gesture handler.
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Image.asset(
                      tool.group == 'vehicle'
                          ? ReferenceAssets.deliveryScooter
                          : ReferenceAssets.deliveryParcel,
                      width: 64,
                      height: 64,
                      cacheWidth: 160,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        ar ? tool.ar : tool.en,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Icon(
                      tool.icon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (tool.id == 'vehicle-change')
              Card(
                child: ListTile(
                  leading: const Icon(Icons.car_rental_outlined),
                  title: Text(ar ? 'تغيير المركبة بطلب رسمي'
                      : 'Change vehicle through a request'),
                  subtitle: Text(ar
                      ? 'اختر نوع المركبة الجديدة واذكر السبب. ستظهر طلباتك أدناه، وتظل المركبة الحالية مسندة حتى مراجعة الطلب من الإدارة.'
                      : 'Select a replacement vehicle type and explain why. Requests appear below; your current vehicle remains assigned until operations reviews the request.'),
                ),
              ),
            if (tool.pending)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  ar
                      ? 'يمكنك تعبئة النموذج الآن. تفعيل الحفظ يتطلب دعم الخدمة من السيرفر.'
                      : 'You can fill in the form. Saving requires the server to support this service.',
                ),
              ),
            if (canEdit)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FilledButton.icon(
                  onPressed: _busy ? null : () => _form(data.valueOrNull),
                  icon: Icon(
                    tool.id == 'incidents' || tool.id == 'emergency'
                        ? Icons.add
                        : Icons.edit_outlined,
                  ),
                  label: Text(
                    ar
                        ? (tool.id == 'incidents'
                              ? 'بلاغ جديد'
                              : tool.id == 'maintenance'
                              ? 'تسجيل صيانة'
                              : tool.id == 'availability'
                              ? 'إضافة فترة'
                              : tool.id == 'vehicle-change'
                              ? 'طلب تغيير المركبة'
                              : tool.id == 'emergency'
                              ? 'إرسال بلاغ عاجل'
                              : 'تعديل وحفظ')
                        : (tool.id == 'incidents'
                              ? 'New report'
                              : tool.id == 'availability'
                              ? 'Add window'
                              : tool.id == 'vehicle-change'
                              ? 'Request vehicle change'
                              : tool.id == 'maintenance'
                              ? 'Record service'
                              : tool.id == 'emergency'
                              ? 'Send urgent report'
                              : 'Edit & save'),
                  ),
                ),
              ),
            ..._links(context),
            if (tool.id == 'avatar') ...[
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _avatar(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(ar ? 'التقاط صورة' : 'Take photo'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _avatar(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(ar ? 'اختيار صورة' : 'Choose photo'),
              ),
            ],
            if (tool.id == 'health') const _PermissionChecks(),
            if (tool.id == 'shifts') const DriverControlPanel(),
            if (tool.id == 'training')
              ..._guide(context)
            else
              data.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_off,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          e is ApiException && e.statusCode == 404
                              ? toolText(
                                  context,
                                  'الخدمة غير متاحة في نسخة السيرفر الحالية.',
                                  'This service is not available on the current server.',
                                )
                              : '$e',
                        ),
                        Text(ar
                            ? 'اسحب للأسفل لإعادة المحاولة'
                            : 'Pull down to retry'),
                      ],
                    ),
                  ),
                ),
                data: (payload) => _content(context, payload),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _links(BuildContext c) {
    final links = switch (tool.id) {
      'phone-change' => {
        '/tools/phone-confirm': ('لدي رمز التحقق', 'Enter verification code'),
      },
      'vehicle' => {
        '/tools/vehicle-change': (
          'طلب تغيير المركبة',
          'Request vehicle change',
        ),
        '/tools/maintenance': ('سجل الصيانة', 'Maintenance history'),
        '/tools/documents': ('وثائق المركبة', 'Vehicle documents'),
      },
      'documents' || 'identity' => {
        '/upload-document': ('رفع مستند أو تجديده', 'Upload or renew document'),
      },
      'payout-status' ||
      'bank' => {'/payouts': ('طلب سحب ومتابعته', 'Request & track payout')},
      'earnings' => {
        '/wallet': ('المحفظة', 'Wallet'),
        '/cash-custody': ('عهدة التحصيل', 'Cash custody'),
        '/tasks/fees': ('تفاصيل رسوم الشحنة', 'Shipment fee breakdown'),
      },
      'account-status' => {
        '/tools/identity': ('التحقق من الهوية', 'Identity verification'),
        '/support': ('الاعتراض والتواصل مع الدعم', 'Appeal & contact support'),
      },
      'privacy' => {
        '/tools/health': ('إدارة أذونات الجهاز', 'Manage device permissions'),
      },
      'preferences' => {
        '/tools/availability': ('جدول التوفر', 'Availability schedule'),
      },
      'emergency' => {'/support': ('التواصل مع الدعم', 'Contact support')},
      _ => <String, (String, String)>{},
    };
    return [
      for (final e in links.entries)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: OutlinedButton.icon(
            onPressed: () async {
              await c.push(e.key);
              if (mounted) ref.invalidate(toolDataProvider(tool.id));
            },
            icon: const Icon(Icons.arrow_outward),
            label: Text(toolText(c, e.value.$1, e.value.$2)),
          ),
        ),
    ];
  }

  Widget _content(BuildContext c, dynamic payload) {
    if (tool.id == 'scheduled-trips') {
      return DriverScheduledTripsTable(rows: recordRows(payload));
    }
    if (tool.id == 'availability') {
      return DriverAvailabilityTable(rows: recordRows(payload));
    }
    if (tool.id == 'service-area') {
      return DriverServiceAreasEditor(rows: recordRows(payload));
    }
    final map = recordMap(payload);
    // A successful 200 with no fields is an empty server result, not a
    // reason to render an invisible blank card. This matters especially for
    // newly-approved drivers who have no sessions, earnings or vehicle yet.
    if (payload == null || (payload is Map && payload.isEmpty)) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(tool.icon, size: 48,
                  color: Theme.of(c).colorScheme.primary),
              const SizedBox(height: 12),
              Text(toolText(c, 'لا توجد بيانات متاحة بعد لهذه الخدمة.',
                  'There is no account data for this service yet.'),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(toolText(c,
                  'اسحب للأسفل للتحديث، أو تحقق من حالة الحساب والاتصال.',
                  'Pull down to refresh or check your account and connection.'),
                  textAlign: TextAlign.center,
                  style: Theme.of(c).textTheme.bodySmall),

            ],
          ),
        ),
      );
    }
    if (tool.id == 'feedback')
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DriverRecordFields(
                record: {
                  'averageDeliveryRating': map['averageDeliveryRating'],
                  'total': map['total'],
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final row in recordRows(payload)) _card(c, row),
          if (recordRows(payload).isEmpty)
            Text(toolText(c, 'لم تصل تقييمات بعد.', 'No feedback yet.')),
        ],
      );
    if (tool.id == 'referral') {
      final code = (map['code'] ?? map['referralCode'])?.toString();
      final invite = driverInviteMessage(code);
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DriverRecordFields(record: map),
              const SizedBox(height: 12),
              Text(toolText(c,
                'صفحة الدعوة مؤقتة؛ معاينة شعار التطبيق تظهر بعد نشرها على السيرفر.',
                'The temporary page shows its branded preview once deployed.')),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: invite));
                  if (c.mounted) ScaffoldMessenger.of(c).showSnackBar(
                    SnackBar(content: Text(toolText(c, 'تم نسخ الدعوة', 'Invitation copied'))),
                  );
                },
                icon: const Icon(Icons.copy_outlined),
                label: Text(toolText(c, 'نسخ رابط الدعوة', 'Copy invitation')),
              ),
              FilledButton.icon(
                onPressed: () async {
                  final uri = driverWhatsAppInviteUri(invite);
                  if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
                      c.mounted) {
                    ScaffoldMessenger.of(c).showSnackBar(
                      SnackBar(content: Text(toolText(c,
                          'تعذر فتح واتساب؛ يمكنك نسخ الرابط.',
                          'Could not open WhatsApp; copy the invite instead.'))),
                    );
                  }
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('WhatsApp'),
              ),
            ],
          ),
        ),
      );
    }
    if (payload is! List &&
        !map.containsKey('items') &&
        !map.containsKey('data'))
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: DriverRecordFields(
            record: map['driver'] is Map
                ? recordMap(map['driver'])
                : map['vehicle'] is Map
                ? recordMap(map['vehicle'])
                : map,
          ),
        ),
      );
    var rows = recordRows(payload);
    if (widget.recordId != null)
      rows = rows
          .where(
            (r) => (recordMap(r['trip'])['id'] ?? r['id']) == widget.recordId,
          )
          .toList();
    if (rows.isEmpty)
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(tool.icon, size: 54, color: Theme.of(c).colorScheme.primary),
            const SizedBox(height: 12),
            Text(toolText(c, 'لا توجد سجلات هنا بعد.', 'No records here yet.')),
          ],
        ),
      );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final r in rows) _card(c, r)],
    );
  }

  Widget _card(BuildContext c, Map<String, dynamic> r) {
    final trip = recordMap(r['trip']);
    final row = trip.isNotEmpty ? trip : r;
    final id = int.tryParse('${row['id'] ?? ''}');
    final action = tool.id == 'returns'
        ? returnAction(row['status'])
        : tool.id == 'scheduled-trips'
        ? participationAction(recordMap(r['participation'])['status'])
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(tool.icon, color: Theme.of(c).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${row['title'] ?? row['name'] ?? toolText(c, tool.ar, tool.en)}${id == null ? '' : ' #$id'}',
                      style: Theme.of(c).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              if (trip.isNotEmpty && r['participation'] != null)
                Text(
                  toolText(
                    c,
                    'حالة طلب الانضمام: ${recordMap(r['participation'])['status']}',
                    'Participation: ${recordMap(r['participation'])['status']}',
                  ),
                ),
              DriverRecordFields(
                record:
                    widget.recordId == null &&
                        {
                          'returns',
                          'documents',
                          'maintenance',
                          'payout-status',
                          'scheduled-trips',
                          'current-trips',
                          'incidents',
                        }.contains(tool.id)
                    ? {
                        for (final key in switch (tool.id) {
                          'scheduled-trips' || 'current-trips' => [
                            'plannedDepartureAt',
                            'plannedArrivalAt',
                            'dropoffName',
                            'status',
                          ],
                          'documents' => ['type', 'status', 'expiresAt'],
                          'maintenance' => [
                            'serviceAt',
                            'odometerKm',
                            'nextServiceAt',
                          ],
                          'payout-status' => [
                            'amount',
                            'currency',
                            'status',
                            'requestedAt',
                          ],
                          'returns' => [
                            'returnRequestId',
                            'status',
                            'returnedAt',
                          ],
                          _ => ['category', 'status', 'createdAt'],
                        })
                          if (row[key] != null) key: row[key],
                      }
                    : row,
              ),
              if (tool.id == 'sessions' && row['id'] is String)
                TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _mutate(
                          () => ref
                              .read(apiClientProvider)
                              .delete(
                                'api/users/me/sessions/${Uri.encodeComponent(row['id'] as String)}',
                              ),
                        ),
                  icon: const Icon(Icons.logout),
                  label: Text(
                    toolText(c, 'إلغاء هذه الجلسة', 'Revoke this session'),
                  ),
                ),
              if (tool.id == 'chats') ...[
                Text('${recordMap(row['otherUser'])['name'] ?? ''}'),
                Text('${recordMap(row['lastMessage'])['body'] ?? ''}'),
                if (row['unreadCount'] != null)
                  Text(
                    '${toolText(c, 'غير مقروءة', 'Unread')}: ${row['unreadCount']}',
                  ),
              ],
              if (row['route'] is Map)
                DriverRecordFields(record: recordMap(row['route'])),
              if (tool.id == 'incentives' &&
                  row['targetShipments'] is num &&
                  row['completedShipments'] is num)
                LinearProgressIndicator(
                  value:
                      ((row['completedShipments'] as num) /
                              (row['targetShipments'] as num).clamp(1, 999999))
                          .clamp(0, 1)
                          .toDouble(),
                ),
              if (tool.id == 'current-trips') ...[
                for (final stop in recordRows(r['stops']))
                  ListTile(
                    leading: CircleAvatar(
                      child: Text('${stop['stopOrder'] ?? ''}'),
                    ),
                    title: Text(
                      '${toolText(c, 'محطة الشحنة', 'Shipment stop')} #${stop['shipmentId']}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: stop['shipmentId'] is num
                        ? () => c.push('/shipments/${stop['shipmentId']}')
                        : null,
                  ),
              ],
              if (tool.id == 'chats' && id != null)
                OutlinedButton.icon(
                  onPressed: () => c.push('/chats/$id'),
                  icon: const Icon(Icons.chat_outlined),
                  label: Text(toolText(c, 'فتح المحادثة', 'Open conversation')),
                ),
              if (tool.id == 'availability' && id != null)
                TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _mutate(
                          () => ref
                              .read(workspaceRepositoryProvider)
                              .deleteWindow(id),
                        ),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(toolText(c, 'حذف الفترة', 'Delete window')),
                ),
              if (action != null && id != null)
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _mutate(
                          () => tool.id == 'returns'
                              ? ref
                                    .read(workspaceRepositoryProvider)
                                    .updateReturn(id, action)
                              : ref
                                    .read(workspaceRepositoryProvider)
                                    .tripAction(id, action),
                        ),
                  child: Text(switch (action) {
                    'join' => toolText(
                      c,
                      'طلب الانضمام للرحلة',
                      'Request to join',
                    ),
                    'withdraw' => toolText(
                      c,
                      'سحب طلب الانضمام',
                      'Withdraw request',
                    ),
                    'accept' => toolText(
                      c,
                      'قبول مهمة المرتجع',
                      'Accept return',
                    ),
                    'pickup' => toolText(
                      c,
                      'استلمت المرتجع',
                      'Picked up return',
                    ),
                    _ => toolText(
                      c,
                      'أعدت المرتجع للمتجر',
                      'Returned to store',
                    ),
                  }),
                ),
              if (tool.id == 'returns' && id != null)
                TextButton(
                  onPressed: () => c.push('/tools/incidents'),
                  child: Text(
                    toolText(c, 'الإبلاغ عن مشكلة', 'Report an issue'),
                  ),
                ),
              if (id != null &&
                  widget.recordId == null &&
                  {
                    'returns',
                    'documents',
                    'maintenance',
                    'payout-status',
                    'scheduled-trips',
                    'current-trips',
                    'incidents',
                  }.contains(tool.id))
                TextButton(
                  onPressed: () => c.push('${tool.route}/$id'),
                  child: Text(toolText(c, 'عرض التفاصيل', 'View details')),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _guide(BuildContext c) => [
    for (final item in const <(String, String, String, String)>[
      (
        'ابدأ يوم العمل',
        'Start your shift',
        'راجع مركبتك ووثائقك، فعّل الموقع ثم ابدأ الوردية لاستقبال العروض.',
        'Check vehicle and documents, enable location, then start a shift.',
      ),
      (
        'راجع العرض قبل قبوله',
        'Review before accepting',
        'راجع المنتجات والحمولة والموقع والمهلة. قبول العرض قرار يُثبت على السيرفر.',
        'Review products, capacity, locations and expiry before accepting.',
      ),
      (
        'تحقق من الاستلام',
        'Verify pickup',
        'عدّ المنتجات وسجل النقص أو التلف قبل تحريك الشحنة.',
        'Count items and report shortages or damage before moving.',
      ),
      (
        'التسليم والتحصيل',
        'Delivery & cash',
        'اتبع التعليمات، احفظ الإثبات، تحقق من رمز العميل واستلم النقد المطلوب كاملًا.',
        'Follow instructions, save proof, verify the customer code and collect the full cash due.',
      ),
      (
        'السلامة والخصوصية',
        'Safety & privacy',
        'توقف في مكان آمن قبل استخدام الهاتف. شارك الموقع أثناء التوفر أو المهام التي فعّلت تتبعها.',
        'Stop safely before using your phone. Location is shared while available or tracking enabled tasks.',
      ),
    ])
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Card(
          child: ExpansionTile(
            title: Text(toolText(c, item.$1, item.$2)),
            childrenPadding: const EdgeInsets.all(16),
            children: [Text(toolText(c, item.$3, item.$4))],
          ),
        ),
      ),
  ];
}

class _PermissionChecks extends StatefulWidget {
  const _PermissionChecks();
  @override
  State<_PermissionChecks> createState() => _PermissionChecksState();
}

class _PermissionChecksState extends State<_PermissionChecks> {
  Map<Permission, PermissionStatus>? _permissions;
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final entries = await Future.wait(
        [
          Permission.locationWhenInUse,
          Permission.camera,
          Permission.notification,
        ].map((p) async => MapEntry(p, await p.status)),
      );
      if (mounted) setState(() => _permissions = Map.fromEntries(entries));
    } catch (_) {
      if (mounted) setState(() => _permissions = {});
    }
  }

  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Card(
      child: Column(
        children: [
          for (final p in [
            Permission.locationWhenInUse,
            Permission.camera,
            Permission.notification,
          ])
            ListTile(
              leading: Icon(
                p == Permission.camera
                    ? Icons.camera_alt_outlined
                    : p == Permission.notification
                    ? Icons.notifications_outlined
                    : Icons.location_on_outlined,
              ),
              title: Text(
                toolText(
                  c,
                  p == Permission.camera
                      ? 'الكاميرا'
                      : p == Permission.notification
                      ? 'الإشعارات'
                      : 'الموقع',
                  p == Permission.camera
                      ? 'Camera'
                      : p == Permission.notification
                      ? 'Notifications'
                      : 'Location',
                ),
              ),
              subtitle: Text('${_permissions?[p] ?? '…'}'),
              onTap: () async {
                await p.request();
                await _refresh();
              },
            ),
          TextButton(
            onPressed: () async {
              await Geolocator.openAppSettings();
              if (mounted) await _refresh();
            },
            child: Text(
              toolText(c, 'فتح إعدادات الجهاز', 'Open device settings'),
            ),
          ),
        ],
      ),
    ),
  );
}
