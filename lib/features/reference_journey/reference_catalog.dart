import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';

enum ReferenceDataSource {
  driver,
  shipments,
  shipmentDetail,
  tracking,
  wallet,
  walletTransactions,
  notifications,
  vehicle,
  supportFaqs,
  supportTickets,
  chats,
  deliveryZones,
  returns,
}

enum ReferenceAction {
  pickupShipment,
  deliverShipment,
  failShipment,
  createIncident,
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

abstract final class ReferenceCatalog {
  static const screens = <ReferenceScreenSpec>[
    ReferenceScreenSpec(
      number: 1,
      titleAr: 'البداية والترحيب',
      titleEn: 'Welcome & onboarding',
      descriptionAr: 'تقديم تجربة السائق وهوية مزرعتي قبل تسجيل الدخول.',
    ),
    ReferenceScreenSpec(
      number: 2,
      titleAr: 'تسجيل الدخول',
      titleEn: 'Driver login',
      descriptionAr: 'الدخول بحساب السائق الحقيقي واستعادة الجلسة الآمنة.',
      sources: [ReferenceDataSource.driver],
    ),
    ReferenceScreenSpec(
      number: 3,
      titleAr: 'لوحة السائق',
      titleEn: 'Driver home',
      descriptionAr: 'ملخص مباشر لحساب السائق والشحنات والمحفظة.',
      sources: [
        ReferenceDataSource.driver,
        ReferenceDataSource.shipments,
        ReferenceDataSource.wallet,
      ],
    ),
    ReferenceScreenSpec(
      number: 4,
      titleAr: 'طلباتي اليوم',
      titleEn: "Today's orders",
      descriptionAr: 'الشحنات الحقيقية المخصصة للسائق مرتبة من بيانات السيرفر.',
      sources: [ReferenceDataSource.shipments],
    ),
    ReferenceScreenSpec(
      number: 5,
      titleAr: 'تفاصيل الطلب',
      titleEn: 'Order details',
      descriptionAr: 'تفاصيل أول شحنة حقيقية متاحة للسائق ومواقعها ورسومها.',
      sources: [ReferenceDataSource.shipmentDetail],
      unsupported: [
        'تفاصيل أصناف الطلب ليست ضمن استجابة Shipment الحالية للسائق.',
      ],
    ),
    ReferenceScreenSpec(
      number: 6,
      titleAr: 'الملاحة إلى نقطة الاستلام',
      titleEn: 'Navigate to pickup',
      descriptionAr: 'إحداثيات المتجر والعميل وآخر موقع للسائق وبيانات ETA من التتبع.',
      sources: [ReferenceDataSource.tracking],
      unsupported: [
        'السيرفر يعيد إحداثيات وتتبعاً لكنه لا يعيد تعليمات turn-by-turn؛ الملاحة التفصيلية تعتمد مزود الخرائط على الجهاز.',
      ],
    ),
    ReferenceScreenSpec(
      number: 7,
      titleAr: 'تأكيد الاستلام',
      titleEn: 'Pickup confirmation',
      descriptionAr: 'تأكيد استلام الشحنة عبر مسار pickup الحقيقي في السيرفر.',
      sources: [ReferenceDataSource.shipmentDetail],
      actions: [ReferenceAction.pickupShipment],
      unsupported: [
        'قائمة فحص الأصناف التفصيلية/صور الاستلام غير مدعومة في نموذج Shipment الحالي.',
      ],
    ),
    ReferenceScreenSpec(
      number: 8,
      titleAr: 'تأكيد التسليم',
      titleEn: 'Delivery confirmation',
      descriptionAr: 'تسليم الشحنة فعلياً وتحديث حالتها عبر السيرفر.',
      sources: [ReferenceDataSource.shipmentDetail],
      actions: [ReferenceAction.deliverShipment],
      unsupported: [
        'توقيع العميل أو صورة إثبات التسليم ليست حقولاً مدعومة في مسار deliver الحالي.',
      ],
    ),
    ReferenceScreenSpec(
      number: 9,
      titleAr: 'الأرباح',
      titleEn: 'Earnings',
      descriptionAr: 'الرصيد والحركة المالية الشهرية والمعاملات من محفظة الحساب.',
      sources: [
        ReferenceDataSource.wallet,
        ReferenceDataSource.walletTransactions,
      ],
    ),
    ReferenceScreenSpec(
      number: 10,
      titleAr: 'التحويل إلى الحساب البنكي',
      titleEn: 'Payout',
      descriptionAr: 'عرض الرصيد والحساب المتاحين مع إبقاء التحويل ظاهرًا حتى يدعمه السيرفر.',
      sources: [
        ReferenceDataSource.wallet,
        ReferenceDataSource.walletTransactions,
      ],
      unsupported: [
        'لا يوجد حالياً endpoint لسحب أرباح السائق أو إنشاء payout بنكي.',
      ],
    ),
    ReferenceScreenSpec(
      number: 11,
      titleAr: 'مركز الإشعارات',
      titleEn: 'Notifications',
      descriptionAr: 'إشعارات الحساب الفعلية القادمة من نظام notifications.',
      sources: [ReferenceDataSource.notifications],
    ),
    ReferenceScreenSpec(
      number: 12,
      titleAr: 'الملف الشخصي',
      titleEn: 'Profile',
      descriptionAr: 'بيانات السائق وحالته واعتماده وتقييمه من Drivers API.',
      sources: [ReferenceDataSource.driver],
      unsupported: [
        'تعديل السائق لنفسه غير متاح بمسار self-service؛ PUT Drivers يتطلب صلاحية users.edit.',
      ],
    ),
    ReferenceScreenSpec(
      number: 13,
      titleAr: 'تسجيل السائق الجديد',
      titleEn: 'Driver registration',
      descriptionAr: 'حقول التسجيل المرجعية تبقى ظاهرة مع بيان دعم السيرفر.',
      sources: [ReferenceDataSource.driver],
      unsupported: [
        'إنشاء Driver موجود إدارياً لكنه يتطلب users.create؛ لا يوجد تسجيل ذاتي للسائق في API الحالي.',
      ],
    ),
    ReferenceScreenSpec(
      number: 14,
      titleAr: 'التحقق من الوثائق',
      titleEn: 'Document verification',
      descriptionAr: 'حالة التحقق من السائق ومعلومات تسجيل وتأمين المركبة المتاحة.',
      sources: [ReferenceDataSource.driver, ReferenceDataSource.vehicle],
      unsupported: [
        'لا يوجد workflow مخصص للسائق لرفع وثائق الهوية ومتابعة مراجعتها من هذه الشاشة.',
      ],
    ),
    ReferenceScreenSpec(
      number: 15,
      titleAr: 'المركبة والصيانة',
      titleEn: 'Vehicle and maintenance',
      descriptionAr: 'المركبة الحالية المسندة للسائق وبياناتها الحقيقية.',
      sources: [ReferenceDataSource.vehicle],
      unsupported: [
        'سجل الصيانة ومواعيد الخدمة الدورية غير موجودين كـ driver self-service endpoints.',
      ],
    ),
    ReferenceScreenSpec(
      number: 16,
      titleAr: 'جدولة التوفر',
      titleEn: 'Availability schedule',
      descriptionAr: 'تعرض حالة التشغيل وقبول الطلبات الحقيقية مع مكان الجدولة المرجعي.',
      sources: [ReferenceDataSource.driver],
      unsupported: [
        'لا يوجد endpoint لجدول توفر أسبوعي أو ساعات عمل للسائق.',
      ],
    ),
    ReferenceScreenSpec(
      number: 17,
      titleAr: 'الحوافز والمكافآت',
      titleEn: 'Incentives',
      descriptionAr: 'تعرض مؤشرات الأداء الحقيقية دون اختلاق برنامج حوافز.',
      sources: [
        ReferenceDataSource.driver,
        ReferenceDataSource.shipments,
        ReferenceDataSource.wallet,
      ],
      unsupported: [
        'لا يوجد حالياً كيان/endpoint لبرامج حوافز السائق أو المكافآت المستحقة.',
      ],
    ),
    ReferenceScreenSpec(
      number: 18,
      titleAr: 'مشاكل الطلب',
      titleEn: 'Order issue',
      descriptionAr: 'تفاصيل الشحنة وتذاكر الدعم المتاحة لمعالجة مشكلة حقيقية.',
      sources: [
        ReferenceDataSource.shipmentDetail,
        ReferenceDataSource.supportTickets,
      ],
      unsupported: [
        'تصنيفات مشاكل الطلب المتخصصة ليست schema مستقلاً؛ المتاح تذاكر/شكاوى ودالة fail للشحنة.',
      ],
    ),
    ReferenceScreenSpec(
      number: 19,
      titleAr: 'الدردشة',
      titleEn: 'Chat',
      descriptionAr: 'محادثات الحساب الحقيقية وعدد الرسائل غير المقروءة من Chats API.',
      sources: [ReferenceDataSource.chats],
    ),
    ReferenceScreenSpec(
      number: 20,
      titleAr: 'المساعدة الفورية',
      titleEn: 'Emergency help',
      descriptionAr: 'الأسئلة الشائعة والتذاكر كقنوات دعم مدعومة من السيرفر.',
      sources: [
        ReferenceDataSource.supportFaqs,
        ReferenceDataSource.supportTickets,
      ],
      unsupported: [
        'زر SOS جغرافي مخصص للطوارئ ورقم طوارئ ديناميكي غير موجودين في API الحالي.',
      ],
    ),
    ReferenceScreenSpec(
      number: 21,
      titleAr: 'مركز المساعدة',
      titleEn: 'Help center',
      descriptionAr: 'FAQ والتذاكر الفعلية من مركز الدعم.',
      sources: [
        ReferenceDataSource.supportFaqs,
        ReferenceDataSource.supportTickets,
      ],
    ),
    ReferenceScreenSpec(
      number: 22,
      titleAr: 'التقييمات',
      titleEn: 'Ratings',
      descriptionAr: 'متوسط وعدد تقييمات السائق الحقيقيين من DriverDto.',
      sources: [ReferenceDataSource.driver],
      unsupported: [
        'Reviews API الحالي خاص بالمنتجات وليس بالسائق؛ لا توجد قائمة تعليقات تقييم السائق.',
      ],
    ),
    ReferenceScreenSpec(
      number: 23,
      titleAr: 'سجل الرحلات',
      titleEn: 'Trip history',
      descriptionAr: 'سجل الشحنات الحقيقي وحالاتها وتواريخها.',
      sources: [ReferenceDataSource.shipments],
    ),
    ReferenceScreenSpec(
      number: 24,
      titleAr: 'إحالة سائق جديد',
      titleEn: 'Driver referral',
      descriptionAr: 'واجهة الإحالة موجودة كما في المرجع من دون اختلاق كود إحالة.',
      sources: [ReferenceDataSource.driver],
      unsupported: [
        'لا يوجد نظام referral أو referralCode أو مكافأة إحالة في API الحالي.',
      ],
    ),
    ReferenceScreenSpec(
      number: 25,
      titleAr: 'الطلبات المجمّعة',
      titleEn: 'Batch orders',
      descriptionAr: 'تعرض الشحنات الفعلية التي يمكن للسائق تنفيذها تباعاً.',
      sources: [ReferenceDataSource.shipments],
      unsupported: [
        'لا يوجد كيان Batch Assignment أو مسار يربط عدة شحنات كحزمة تسليم واحدة.',
      ],
    ),
    ReferenceScreenSpec(
      number: 26,
      titleAr: 'مسح رمز QR',
      titleEn: 'QR scanner',
      descriptionAr: 'واجهة المسح والأصل المرجعي موجودان مع توضيح نقص مسار التحقق.',
      sources: [ReferenceDataSource.shipmentDetail],
      unsupported: [
        'لا يوجد endpoint للتحقق من QR خاص بالشحنة أو تأكيد الاستلام عبر رمز.',
      ],
    ),
    ReferenceScreenSpec(
      number: 27,
      titleAr: 'إعادة الطلب',
      titleEn: 'Order return',
      descriptionAr: 'تعرض الشحنة وطلبات الإرجاع المتاحة للحساب من السيرفر.',
      sources: [
        ReferenceDataSource.shipmentDetail,
        ReferenceDataSource.returns,
      ],
      unsupported: [
        'Returns API الحالي موجّه لطلب إرجاع العميل؛ لا يوجد workflow خاص بالسائق لاستلام/إعادة مرتجع.',
      ],
    ),
    ReferenceScreenSpec(
      number: 28,
      titleAr: 'فحص الطلب عند الاستلام',
      titleEn: 'Pickup inspection',
      descriptionAr: 'تعرض بيانات الشحنة مع عناصر الفحص المرجعية كاملة.',
      sources: [ReferenceDataSource.shipmentDetail],
      unsupported: [
        'نتائج فحص الأصناف، الحرارة، الصور، النواقص والتلف غير ممثلة في Shipment schema الحالي.',
      ],
    ),
    ReferenceScreenSpec(
      number: 29,
      titleAr: 'إثبات التسليم',
      titleEn: 'Proof of delivery',
      descriptionAr: 'تعرض حالة الشحنة وموقعها وتبقي حقول الإثبات واضحة.',
      sources: [
        ReferenceDataSource.shipmentDetail,
        ReferenceDataSource.tracking,
      ],
      unsupported: [
        'صورة التسليم وتوقيع العميل وPOD reference غير مدعومة في endpoint deliver الحالي.',
      ],
    ),
    ReferenceScreenSpec(
      number: 30,
      titleAr: 'الحساب البنكي',
      titleEn: 'Bank account',
      descriptionAr: 'تعرض رقم حساب المحفظة الحقيقي مع مكان بيانات البنك المرجعية.',
      sources: [ReferenceDataSource.wallet],
      unsupported: [
        'لا توجد BankAccount entity/endpoint للسائق ولا IBAN محفوظ قابل للتعديل في API الحالي.',
      ],
    ),
    ReferenceScreenSpec(
      number: 31,
      titleAr: 'اللغة والخصوصية',
      titleEn: 'Language & privacy',
      descriptionAr: 'إعدادات واجهة محلية مع معلومات الحساب الحقيقية.',
      sources: [ReferenceDataSource.driver],
      unsupported: [
        'تفضيلات اللغة والخصوصية ليست محفوظة في ملف السائق على السيرفر حالياً.',
      ],
    ),
    ReferenceScreenSpec(
      number: 32,
      titleAr: 'مستوى السائق',
      titleEn: 'Driver tier',
      descriptionAr: 'تعرض التقييم والرحلات والأرصدة كبيانات أداء حقيقية.',
      sources: [
        ReferenceDataSource.driver,
        ReferenceDataSource.shipments,
        ReferenceDataSource.wallet,
      ],
      unsupported: [
        'لا يوجد DriverTier أو حدود Bronze/Silver/Gold محفوظة في السيرفر.',
      ],
    ),
    ReferenceScreenSpec(
      number: 33,
      titleAr: 'تقييم العميل',
      titleEn: 'Customer feedback',
      descriptionAr: 'تعرض التقييم المجمع للسائق دون إنشاء تعليقات وهمية.',
      sources: [ReferenceDataSource.driver],
      unsupported: [
        'لا توجد تعليقات customer-to-driver أو تقييمات رحلة مفصلة في API الحالي.',
      ],
    ),
    ReferenceScreenSpec(
      number: 34,
      titleAr: 'تفضيلات الإشعارات',
      titleEn: 'Notification preferences',
      descriptionAr: 'تعرض الإشعارات الفعلية مع خيارات المرجع كاملة.',
      sources: [ReferenceDataSource.notifications],
      unsupported: [
        'لا يوجد endpoint لحفظ تفضيلات أنواع إشعارات السائق أو ساعات الكتم.',
      ],
    ),
    ReferenceScreenSpec(
      number: 35,
      titleAr: 'مناطق الخدمة',
      titleEn: 'Service zones',
      descriptionAr: 'مناطق التوصيل الفعلية من DeliveryZones API.',
      sources: [ReferenceDataSource.deliveryZones],
      unsupported: [
        'لا يوجد ربط واضح بين السائق ومجموعة مناطق خدمة مفضلة/مسموح بها في ملف Driver.',
      ],
    ),
    ReferenceScreenSpec(
      number: 36,
      titleAr: 'حالة النظام',
      titleEn: 'System status',
      descriptionAr: 'تعرض نجاح مصادر السيرفر المستخدمة في التطبيق دون اختلاق uptime.',
      sources: [ReferenceDataSource.driver],
      unsupported: [
        'لا يوجد endpoint مخصص لحالة الخدمات/uptime/الحوادث التشغيلية.',
      ],
    ),
    ReferenceScreenSpec(
      number: 37,
      titleAr: 'التحصيل النقدي',
      titleEn: 'Cash collection',
      descriptionAr: 'تعرض الشحنات والحركات المالية الحقيقية ذات الصلة.',
      sources: [
        ReferenceDataSource.shipments,
        ReferenceDataSource.walletTransactions,
      ],
      unsupported: [
        'لا يعيد Shipment list طريقة الدفع أو مبلغ COD المطلوب تحصيله كسجل مستقل للسائق.',
      ],
    ),
    ReferenceScreenSpec(
      number: 38,
      titleAr: 'إيصال التحويل',
      titleEn: 'Payout receipt',
      descriptionAr: 'تعرض بيانات المحفظة والمعاملات وتبقي نموذج الإيصال المرجعي.',
      sources: [
        ReferenceDataSource.wallet,
        ReferenceDataSource.walletTransactions,
      ],
      unsupported: [
        'لعدم وجود payout للسائق فلا يوجد payout receipt/reference بنكي حقيقي حالياً.',
      ],
    ),
    ReferenceScreenSpec(
      number: 39,
      titleAr: 'تعذر الوصول للعميل',
      titleEn: 'Customer unavailable',
      descriptionAr: 'الموقع والتتبع الحقيقيان مع إمكانية تسجيل فشل التسليم وسببه.',
      sources: [
        ReferenceDataSource.shipmentDetail,
        ReferenceDataSource.tracking,
      ],
      actions: [ReferenceAction.failShipment],
    ),
    ReferenceScreenSpec(
      number: 40,
      titleAr: 'تعليمات الوصول',
      titleEn: 'Access instructions',
      descriptionAr: 'تعرض إحداثيات العميل الحقيقية وتحتفظ بمكان التعليمات.',
      sources: [ReferenceDataSource.shipmentDetail],
      unsupported: [
        'استجابة Shipment للسائق لا تتضمن ملاحظات العنوان أو بوابة/طابق/علامة مميزة.',
      ],
    ),
    ReferenceScreenSpec(
      number: 41,
      titleAr: 'الإنجازات',
      titleEn: 'Achievements',
      descriptionAr: 'تعرض الأرقام الحقيقية للتقييم والشحنات والمحفظة.',
      sources: [
        ReferenceDataSource.driver,
        ReferenceDataSource.shipments,
        ReferenceDataSource.wallet,
      ],
      unsupported: [
        'لا توجد achievements/badges محفوظة في السيرفر؛ لا يتم منح شارات وهمية من التطبيق.',
      ],
    ),
    ReferenceScreenSpec(
      number: 42,
      titleAr: 'تفاصيل المركبة',
      titleEn: 'Vehicle details',
      descriptionAr: 'بيانات المركبة الحالية: النوع واللوحة والطراز والتأمين والتسجيل.',
      sources: [ReferenceDataSource.vehicle],
    ),
    ReferenceScreenSpec(
      number: 43,
      titleAr: 'تجديد الوثائق',
      titleEn: 'Document renewal',
      descriptionAr: 'تعرض تواريخ انتهاء تسجيل وتأمين المركبة وحالة السائق.',
      sources: [ReferenceDataSource.vehicle, ReferenceDataSource.driver],
      unsupported: [
        'لا يوجد طلب تجديد/رفع مستند جديد للسائق ضمن Vehicles أو Drivers self-service API.',
      ],
    ),
    ReferenceScreenSpec(
      number: 44,
      titleAr: 'الحساب موقوف',
      titleEn: 'Account paused',
      descriptionAr: 'حالة الحساب والموافقة والإيقاف والسبب إن أعاده السيرفر.',
      sources: [ReferenceDataSource.driver],
    ),
    ReferenceScreenSpec(
      number: 45,
      titleAr: 'رفع بلاغ',
      titleEn: 'Incident report',
      descriptionAr: 'قائمة التذاكر الحقيقية مع إمكانية إنشاء شكوى من نفس الشاشة.',
      sources: [ReferenceDataSource.supportTickets],
      actions: [ReferenceAction.createIncident],
    ),
    ReferenceScreenSpec(
      number: 46,
      titleAr: 'تفاصيل الرسوم',
      titleEn: 'Fee breakdown',
      descriptionAr: 'DeliveryFee وTransportCost وNetProfit والحركات المالية من السيرفر.',
      sources: [
        ReferenceDataSource.shipmentDetail,
        ReferenceDataSource.walletTransactions,
      ],
      unsupported: [
        'تفصيل عمولة المنصة/الضريبة/الحوافز كعناصر منفصلة غير موجود في Shipment DTO الحالي.',
      ],
    ),
    ReferenceScreenSpec(
      number: 47,
      titleAr: 'التحقق من الهوية',
      titleEn: 'Identity verification',
      descriptionAr: 'IsVerified وApprovalStatus الفعليان من ملف السائق.',
      sources: [ReferenceDataSource.driver],
      unsupported: [
        'لا توجد جلسة KYC ذات خطوات أو صور هوية قابلة للرفع/المراجعة من تطبيق السائق.',
      ],
    ),
    ReferenceScreenSpec(
      number: 48,
      titleAr: 'إغلاق اليوم',
      titleEn: 'End-of-day summary',
      descriptionAr: 'ملخص من بيانات السائق والشحنات والمحفظة والمعاملات الحقيقية.',
      sources: [
        ReferenceDataSource.driver,
        ReferenceDataSource.shipments,
        ReferenceDataSource.wallet,
        ReferenceDataSource.walletTransactions,
      ],
      unsupported: [
        'لا يوجد endpoint لعملية إغلاق يوم/تسوية وردية للسائق؛ الشاشة ملخص قراءة فقط حتى يضاف.',
      ],
    ),
  ];

  static ReferenceScreenSpec screen(int number) => screens.firstWhere(
        (item) => item.number == number,
        orElse: () => screens.first,
      );
}
