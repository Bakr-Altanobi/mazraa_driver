import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';

enum ReferenceDataSource {
  driver,
  journeyMe,
  preferences,
  availability,
  offers,
  scheduledTrips,
  currentTrips,
  shifts,
  shipments,
  shipmentDetail,
  tracking,
  shipmentProofs,
  wallet,
  walletTransactions,
  notifications,
  vehicle,
  documents,
  vehicleMaintenance,
  bankAccounts,
  payouts,
  incentives,
  referral,
  incidents,
  returns,
  performance,
  supportFaqs,
  supportTickets,
  chats,
  deliveryZones,
}

enum ReferenceAction {
  acceptShipment,
  pickupShipment,
  startTransit,
  nearCustomer,
  deliverShipment,
  failShipment,
  startShift,
  endShift,
  acceptOffer,
  rejectOffer,
  createIncident,
  goOnline,
  goOffline,
  joinScheduledTrip,
  withdrawScheduledTrip,
  acceptReturn,
  pickupReturn,
  completeReturn,
  addPickupProof,
  addDeliveryProof,
  saveBankAccount,
  requestPayout,
  markAllNotificationsRead,
}

class ReferenceScreenSpec {
  const ReferenceScreenSpec({
    required this.number,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    this.sources = const [],
    this.unsupported = const [],
    this.actions = const [],
  });

  final int number;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final List<ReferenceDataSource> sources;
  final List<String> unsupported;
  final List<ReferenceAction> actions;

  String get route => '/journey/${number.toString().padLeft(2, '0')}';
  List<ReferenceAssetSlot> get assets =>
      ReferenceAssets.byScreen[number] ?? const [];
}

/// Canonical 48-screen journey.
///
/// Screen identity and artwork come from the reference files and
/// ASSET_INDEX.csv. Business values are sourced only from server contracts.
/// [unsupported] is reserved for reference capabilities that still have no
/// server contract; supported driver-journey features are intentionally not
/// represented with fake or disabled data.
abstract final class ReferenceCatalog {
  static const screens = <ReferenceScreenSpec>[
    ReferenceScreenSpec(
      number: 1,
      titleAr: 'البداية والترحيب',
      titleEn: 'Onboarding',
      descriptionAr: 'تقديم تجربة السائق وهوية مزرعتي قبل تسجيل الدخول.',
    ),
    ReferenceScreenSpec(
      number: 2,
      titleAr: 'تسجيل الدخول والتحقق',
      titleEn: 'Login & OTP',
      descriptionAr: 'تسجيل دخول السائق الحقيقي واستعادة الجلسة الآمنة.',
      sources: [ReferenceDataSource.driver],
      unsupported: [
        'مرجع التصميم يعرض OTP، بينما تسجيل دخول السائق الحالي يعتمد البريد وكلمة المرور ولا يوفر OTP مخصصاً للسائق.',
      ],
    ),
    ReferenceScreenSpec(
      number: 3,
      titleAr: 'لوحة السائق',
      titleEn: 'Driver home / offline',
      descriptionAr: 'ملخص مباشر لحالة التشغيل والشحنات والمحفظة والوردية.',
      sources: [
        ReferenceDataSource.journeyMe,
        ReferenceDataSource.shipments,
        ReferenceDataSource.wallet,
        ReferenceDataSource.shifts,
      ],
      actions: [ReferenceAction.goOnline, ReferenceAction.goOffline],
    ),
    ReferenceScreenSpec(
      number: 4,
      titleAr: 'قائمة الطلبات',
      titleEn: 'Orders list',
      descriptionAr: 'الشحنات المسندة والعروض الفعلية المتاحة للسائق.',
      sources: [ReferenceDataSource.shipments, ReferenceDataSource.offers],
      actions: [ReferenceAction.acceptOffer, ReferenceAction.rejectOffer],
    ),
    ReferenceScreenSpec(
      number: 5,
      titleAr: 'تفاصيل الطلب',
      titleEn: 'Order detail',
      descriptionAr: 'تفاصيل الشحنة الحقيقية مع قبول الشحنة المسندة من السيرفر.',
      sources: [ReferenceDataSource.shipmentDetail],
      actions: [ReferenceAction.acceptShipment],
      unsupported: [
        'تفاصيل أصناف الطلب ليست ضمن استجابة Shipment الحالية للسائق.',
      ],
    ),
    ReferenceScreenSpec(
      number: 6,
      titleAr: 'الملاحة إلى نقطة الاستلام',
      titleEn: 'Navigation to pickup',
      descriptionAr: 'إحداثيات الاستلام والعميل وآخر موقع للسائق من التتبع الحقيقي.',
      sources: [ReferenceDataSource.tracking],
      unsupported: [
        'تعليمات turn-by-turn نفسها يقدمها مزود الخرائط على الجهاز وليست عقداً في السيرفر.',
      ],
    ),
    ReferenceScreenSpec(
      number: 7,
      titleAr: 'التحقق من الاستلام',
      titleEn: 'Pickup verification',
      descriptionAr: 'تأكيد الاستلام ثم بدء الانتقال للشحنة الفعلية.',
      sources: [ReferenceDataSource.shipmentDetail, ReferenceDataSource.shipmentProofs],
      actions: [ReferenceAction.addPickupProof, ReferenceAction.pickupShipment, ReferenceAction.startTransit],
      unsupported: [
        'قائمة أصناف فحص مستقلة لكل شحنة ليست ضمن Shipment DTO الحالي.',
      ],
    ),
    ReferenceScreenSpec(
      number: 8,
      titleAr: 'تسليم الطلب للعميل',
      titleEn: 'Delivery handoff',
      descriptionAr: 'الوصول للعميل ثم التسليم أو تسجيل فشل التسليم وفق حالة الشحنة.',
      sources: [
        ReferenceDataSource.shipmentDetail,
        ReferenceDataSource.tracking,
        ReferenceDataSource.shipmentProofs,
      ],
      actions: [
        ReferenceAction.nearCustomer,
        ReferenceAction.deliverShipment,
        ReferenceAction.failShipment,
      ],
    ),
    ReferenceScreenSpec(
      number: 9,
      titleAr: 'الأرباح',
      titleEn: 'Earnings',
      descriptionAr: 'الرصيد والحركة المالية الفعلية من محفظة السائق.',
      sources: [ReferenceDataSource.wallet, ReferenceDataSource.walletTransactions],
    ),
    ReferenceScreenSpec(
      number: 10,
      titleAr: 'المحفظة والتحويل',
      titleEn: 'Wallet payout',
      descriptionAr: 'الرصيد والحساب البنكي وطلبات السحب الفعلية من السيرفر.',
      sources: [
        ReferenceDataSource.wallet,
        ReferenceDataSource.walletTransactions,
        ReferenceDataSource.bankAccounts,
        ReferenceDataSource.payouts,
      ],
      actions: [ReferenceAction.requestPayout],
    ),
    ReferenceScreenSpec(
      number: 11,
      titleAr: 'مركز الإشعارات',
      titleEn: 'Notifications',
      descriptionAr: 'إشعارات الحساب الفعلية القادمة من Notifications API.',
      sources: [ReferenceDataSource.notifications],
      actions: [ReferenceAction.markAllNotificationsRead],
    ),
    ReferenceScreenSpec(
      number: 12,
      titleAr: 'الملف الشخصي والإعدادات',
      titleEn: 'Profile settings',
      descriptionAr: 'بيانات السائق وحالة التشغيل وتفضيلات قبول الرحلات.',
      sources: [ReferenceDataSource.journeyMe, ReferenceDataSource.preferences],
      actions: [ReferenceAction.goOnline, ReferenceAction.goOffline],
    ),
    ReferenceScreenSpec(
      number: 13,
      titleAr: 'تسجيل سائق جديد',
      titleEn: 'Driver registration',
      descriptionAr: 'الحقول المرجعية مع حالة حساب السائق الحالية.',
      sources: [ReferenceDataSource.driver],
      unsupported: [
        'لا يوجد حتى الآن تسجيل public مستقل لسائق غير مسجل الدخول؛ طلب الانضمام الحالي يبدأ من مستخدم موثق.',
      ],
    ),
    ReferenceScreenSpec(
      number: 14,
      titleAr: 'وثائق المركبة والسائق',
      titleEn: 'Vehicle documents',
      descriptionAr: 'وثائق السائق والمركبة وحالة مراجعتها من driver-journey.',
      sources: [
        ReferenceDataSource.journeyMe,
        ReferenceDataSource.vehicle,
        ReferenceDataSource.documents,
      ],
    ),
    ReferenceScreenSpec(
      number: 15,
      titleAr: 'ملف المركبة',
      titleEn: 'Vehicle profile',
      descriptionAr: 'المركبة الحالية وسجل الصيانة والخدمة الفعلي.',
      sources: [ReferenceDataSource.vehicle, ReferenceDataSource.vehicleMaintenance],
    ),
    ReferenceScreenSpec(
      number: 16,
      titleAr: 'جدول التوفر',
      titleEn: 'Availability schedule',
      descriptionAr: 'نوافذ التوفر الأسبوعية والتفضيلات والوردية من السيرفر.',
      sources: [
        ReferenceDataSource.journeyMe,
        ReferenceDataSource.availability,
        ReferenceDataSource.preferences,
        ReferenceDataSource.shifts,
      ],
      actions: [ReferenceAction.startShift, ReferenceAction.endShift, ReferenceAction.joinScheduledTrip, ReferenceAction.withdrawScheduledTrip],
    ),
    ReferenceScreenSpec(
      number: 17,
      titleAr: 'الحوافز والمكافآت',
      titleEn: 'Incentives',
      descriptionAr: 'الحوافز المحفوظة ومؤشرات الأداء الفعلية للسائق.',
      sources: [
        ReferenceDataSource.incentives,
        ReferenceDataSource.performance,
        ReferenceDataSource.wallet,
      ],
    ),
    ReferenceScreenSpec(
      number: 18,
      titleAr: 'مشكلة في الطلب',
      titleEn: 'Order issue',
      descriptionAr: 'تفاصيل الشحنة وبلاغات السائق مع إمكانية تسجيل تعذر التسليم.',
      sources: [ReferenceDataSource.shipmentDetail, ReferenceDataSource.incidents],
      actions: [ReferenceAction.createIncident, ReferenceAction.failShipment],
    ),
    ReferenceScreenSpec(
      number: 19,
      titleAr: 'محادثة العميل',
      titleEn: 'Customer chat',
      descriptionAr: 'محادثات الحساب الحقيقية وعدد الرسائل غير المقروءة.',
      sources: [ReferenceDataSource.chats],
    ),
    ReferenceScreenSpec(
      number: 20,
      titleAr: 'المساعدة الطارئة',
      titleEn: 'Emergency assistance',
      descriptionAr: 'البلاغات وقنوات الدعم الحقيقية المتاحة للسائق.',
      sources: [ReferenceDataSource.incidents, ReferenceDataSource.supportFaqs],
      actions: [ReferenceAction.createIncident],
      unsupported: [
        'الاتصال بخدمات الطوارئ الخارجية يتم من الجهاز ولا يمثل endpoint أعمال داخل السيرفر.',
      ],
    ),
    ReferenceScreenSpec(
      number: 21,
      titleAr: 'مركز الدعم',
      titleEn: 'Support center',
      descriptionAr: 'FAQ والتذاكر الفعلية من مركز الدعم.',
      sources: [ReferenceDataSource.supportFaqs, ReferenceDataSource.supportTickets],
    ),
    ReferenceScreenSpec(
      number: 22,
      titleAr: 'التقييم والملاحظات',
      titleEn: 'Rating feedback',
      descriptionAr: 'متوسط وعدد تقييمات السائق الحقيقيين.',
      sources: [ReferenceDataSource.performance],
      unsupported: [
        'لا توجد حتى الآن قائمة تعليقات نصية customer-to-driver لكل رحلة.',
      ],
    ),
    ReferenceScreenSpec(
      number: 23,
      titleAr: 'لا توجد طلبات',
      titleEn: 'Empty orders',
      descriptionAr: 'حالة الفراغ مبنية على قائمة الشحنات الحقيقية فقط.',
      sources: [ReferenceDataSource.shipments, ReferenceDataSource.offers],
    ),
    ReferenceScreenSpec(
      number: 24,
      titleAr: 'إحالة صديق',
      titleEn: 'Refer a friend',
      descriptionAr: 'كود الإحالة وقائمة السائقين المحالين من السيرفر.',
      sources: [ReferenceDataSource.referral],
    ),
    ReferenceScreenSpec(
      number: 25,
      titleAr: 'سجل الرحلات',
      titleEn: 'Trip history',
      descriptionAr: 'الشحنات والرحلات الحالية والحالات والتواريخ من السيرفر.',
      sources: [ReferenceDataSource.shipments, ReferenceDataSource.currentTrips],
    ),
    ReferenceScreenSpec(
      number: 26,
      titleAr: 'مسح رمز QR',
      titleEn: 'QR scan',
      descriptionAr: 'QR يمكن تمريره كإثبات عند التسليم للشحنة المؤهلة.',
      sources: [ReferenceDataSource.shipmentDetail, ReferenceDataSource.shipmentProofs],
      unsupported: [
        'لا يوجد endpoint منفصل لفحص QR قبل خطوة التسليم؛ التحقق مرتبط بعملية التسليم نفسها.',
      ],
    ),
    ReferenceScreenSpec(
      number: 27,
      titleAr: 'الطلبات المجمّعة',
      titleEn: 'Batch orders',
      descriptionAr: 'الرحلات الحالية وتوقفاتها وشحناتها الفعلية من السيرفر.',
      sources: [
        ReferenceDataSource.currentTrips,
        ReferenceDataSource.shipments,
        ReferenceDataSource.preferences,
        ReferenceDataSource.scheduledTrips,
      ],
      actions: [ReferenceAction.joinScheduledTrip, ReferenceAction.withdrawScheduledTrip],
    ),
    ReferenceScreenSpec(
      number: 28,
      titleAr: 'فحص محتويات الاستلام',
      titleEn: 'Pickup inventory',
      descriptionAr: 'بيانات الشحنة وإثباتاتها الفعلية مع عناصر الفحص المرجعية.',
      sources: [ReferenceDataSource.shipmentDetail, ReferenceDataSource.shipmentProofs],
      unsupported: [
        'قائمة أصناف الشحنة التفصيلية ونتيجة فحص كل صنف ليست ضمن Shipment DTO الحالي.',
      ],
    ),
    ReferenceScreenSpec(
      number: 29,
      titleAr: 'إثبات التسليم',
      titleEn: 'Delivery proof',
      descriptionAr: 'إثباتات الشحنة الفعلية من ShipmentProof مع موقع التتبع.',
      sources: [
        ReferenceDataSource.shipmentDetail,
        ReferenceDataSource.tracking,
        ReferenceDataSource.shipmentProofs,
      ],
      actions: [ReferenceAction.addDeliveryProof],
    ),
    ReferenceScreenSpec(
      number: 30,
      titleAr: 'تعديل الحساب البنكي',
      titleEn: 'Bank account edit',
      descriptionAr: 'الحسابات البنكية الفعلية للسائق من driver-journey.',
      sources: [ReferenceDataSource.bankAccounts, ReferenceDataSource.wallet],
      actions: [ReferenceAction.saveBankAccount],
    ),
    ReferenceScreenSpec(
      number: 31,
      titleAr: 'اللغة والخصوصية',
      titleEn: 'Language & privacy',
      descriptionAr: 'إعدادات واجهة محلية مع معلومات الحساب الحقيقية.',
      sources: [ReferenceDataSource.journeyMe],
      unsupported: [
        'تفضيل لغة واجهة التطبيق وتفضيلات الخصوصية العامة ليست حقولاً في ملف السائق على السيرفر.',
      ],
    ),
    ReferenceScreenSpec(
      number: 32,
      titleAr: 'لوحة الأداء',
      titleEn: 'Performance dashboard',
      descriptionAr: 'التقييم والإنجاز والفشل ونسبة قبول العروض من performance API.',
      sources: [ReferenceDataSource.performance, ReferenceDataSource.wallet],
    ),
    ReferenceScreenSpec(
      number: 33,
      titleAr: 'تفصيل تقييم السائق',
      titleEn: 'Driver rating breakdown',
      descriptionAr: 'متوسط وعدد التقييمات الحقيقيان من performance API.',
      sources: [ReferenceDataSource.performance],
      unsupported: [
        'توزيع النجوم 1–5 والتعليقات النصية لكل رحلة غير متاحين حتى الآن.',
      ],
    ),
    ReferenceScreenSpec(
      number: 34,
      titleAr: 'تفضيلات الإشعارات',
      titleEn: 'Notification preferences',
      descriptionAr: 'الإشعارات الفعلية مع خيارات الواجهة المرجعية.',
      sources: [ReferenceDataSource.notifications],
      unsupported: [
        'حفظ تفضيلات أنواع الإشعارات وساعات الكتم ليس له endpoint مخصص حالياً.',
      ],
    ),
    ReferenceScreenSpec(
      number: 35,
      titleAr: 'منطقة الخدمة',
      titleEn: 'Service area',
      descriptionAr: 'مناطق التوصيل الفعلية مع نطاق قبول العروض في تفضيلات السائق.',
      sources: [ReferenceDataSource.deliveryZones, ReferenceDataSource.preferences],
      unsupported: [
        'قائمة مناطق خدمة مفضلة للسائق بالمعرفات ليست محفوظة حالياً؛ المتاح نطاق العروض بالكيلومتر.',
      ],
    ),
    ReferenceScreenSpec(
      number: 36,
      titleAr: 'حالة النظام',
      titleEn: 'System status',
      descriptionAr: 'نجاح الاتصال بعقد driver-journey/me وحالة الحساب الفعلية.',
      sources: [ReferenceDataSource.journeyMe],
      unsupported: [
        'لا يوجد feed منفصل لزمن التشغيل أو حوادث البنية التحتية داخل Driver API.',
      ],
    ),
    ReferenceScreenSpec(
      number: 37,
      titleAr: 'التحصيل النقدي',
      titleEn: 'Cash collection',
      descriptionAr: 'الشحنات والحركات المالية الفعلية ذات الصلة.',
      sources: [ReferenceDataSource.shipments, ReferenceDataSource.walletTransactions],
      unsupported: [
        'لا يوجد سجل تسوية COD مستقل للسائق عن حركات المحفظة الحالية.',
      ],
    ),
    ReferenceScreenSpec(
      number: 38,
      titleAr: 'نجاح التحويل',
      titleEn: 'Payout success',
      descriptionAr: 'طلبات السحب وحالاتها ومراجع المزود والحسابات البنكية الفعلية.',
      sources: [
        ReferenceDataSource.payouts,
        ReferenceDataSource.bankAccounts,
        ReferenceDataSource.wallet,
      ],
    ),
    ReferenceScreenSpec(
      number: 39,
      titleAr: 'إرجاع الطلب',
      titleEn: 'Return order',
      descriptionAr: 'مهام المرتجع المسندة للسائق وحالات تنفيذها الفعلية.',
      sources: [ReferenceDataSource.returns, ReferenceDataSource.shipmentDetail],
      actions: [ReferenceAction.acceptReturn, ReferenceAction.pickupReturn, ReferenceAction.completeReturn],
    ),
    ReferenceScreenSpec(
      number: 40,
      titleAr: 'تعذر الوصول للعميل',
      titleEn: 'Customer unavailable',
      descriptionAr: 'الموقع والتتبع مع تسجيل فشل التسليم وسببه على الشحنة.',
      sources: [ReferenceDataSource.shipmentDetail, ReferenceDataSource.tracking],
      actions: [ReferenceAction.failShipment],
      unsupported: [
        'عدد محاولات الاتصال الهاتفية ليس حقلاً مستقلاً في Shipment DTO.',
      ],
    ),
    ReferenceScreenSpec(
      number: 41,
      titleAr: 'ملخص الوردية',
      titleEn: 'Shift summary',
      descriptionAr: 'سجل الورديات مع الأداء والمحفظة الفعلية.',
      sources: [
        ReferenceDataSource.shifts,
        ReferenceDataSource.performance,
        ReferenceDataSource.wallet,
        ReferenceDataSource.walletTransactions,
      ],
      actions: [ReferenceAction.startShift, ReferenceAction.endShift],
    ),
    ReferenceScreenSpec(
      number: 42,
      titleAr: 'صيانة المركبة',
      titleEn: 'Vehicle maintenance',
      descriptionAr: 'المركبة وسجل الصيانة ومواعيد الخدمة القادمة من السيرفر.',
      sources: [ReferenceDataSource.vehicle, ReferenceDataSource.vehicleMaintenance],
    ),
    ReferenceScreenSpec(
      number: 43,
      titleAr: 'انتهاء الوثائق',
      titleEn: 'Document expiry',
      descriptionAr: 'وثائق السائق والمركبة وتواريخ الانتهاء وحالة المراجعة.',
      sources: [
        ReferenceDataSource.documents,
        ReferenceDataSource.vehicle,
        ReferenceDataSource.journeyMe,
      ],
    ),
    ReferenceScreenSpec(
      number: 44,
      titleAr: 'الحساب موقوف',
      titleEn: 'Account paused',
      descriptionAr: 'حالة الحساب والموافقة والإيقاف والسبب من ملف السائق.',
      sources: [ReferenceDataSource.journeyMe],
    ),
    ReferenceScreenSpec(
      number: 45,
      titleAr: 'رفع بلاغ',
      titleEn: 'Incident report',
      descriptionAr: 'بلاغات السائق الفعلية مع إنشاء بلاغ جديد من driver-journey.',
      sources: [ReferenceDataSource.incidents],
      actions: [ReferenceAction.createIncident],
    ),
    ReferenceScreenSpec(
      number: 46,
      titleAr: 'تفاصيل الرسوم',
      titleEn: 'Fee breakdown',
      descriptionAr: 'رسوم الشحنة والحركات المالية والحوافز الفعلية المتاحة.',
      sources: [
        ReferenceDataSource.shipmentDetail,
        ReferenceDataSource.walletTransactions,
        ReferenceDataSource.incentives,
      ],
      unsupported: [
        'تفصيل عمولة المنصة والضريبة كسطرين مستقلين داخل Shipment DTO غير متاح حالياً.',
      ],
    ),
    ReferenceScreenSpec(
      number: 47,
      titleAr: 'التحقق من الهوية',
      titleEn: 'Identity verification',
      descriptionAr: 'حالة التحقق ووثائق السائق ومراجعتها من السيرفر.',
      sources: [ReferenceDataSource.journeyMe, ReferenceDataSource.documents],
      unsupported: [
        'لا توجد جلسة KYC متعددة الخطوات منفصلة؛ التحقق الحالي مبني على ملف السائق وسجلات الوثائق.',
      ],
    ),
    ReferenceScreenSpec(
      number: 48,
      titleAr: 'ملاحظات العميل',
      titleEn: 'Customer feedback',
      descriptionAr: 'متوسط وعدد تقييمات السائق الحقيقيين من performance API.',
      sources: [ReferenceDataSource.performance],
      unsupported: [
        'لا توجد قائمة تعليقات نصية من العملاء على السائق لكل رحلة حتى الآن.',
      ],
    ),
  ];

  static ReferenceScreenSpec screen(int number) => screens.firstWhere(
        (item) => item.number == number,
        orElse: () => screens.first,
      );
}
