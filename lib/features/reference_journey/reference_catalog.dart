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

/// Canonical 48-screen journey.
///
/// Screen identity follows the actual PNG reference filenames under
/// `refrinces/screens*`. ASSET_INDEX.csv is authoritative for the five artwork
/// slots of each screen. Server-backed values come only from the API sources
/// listed here; missing backend contracts are deliberately kept visible in
/// [unsupported] instead of being removed or filled with fake business data.
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
        'مرجع التصميم يعرض OTP، بينما API الحالي لتسجيل دخول السائق يعتمد البريد وكلمة المرور ولا يوفر OTP مخصصاً للسائق.',
      ],
    ),
    ReferenceScreenSpec(
      number: 3,
      titleAr: 'لوحة السائق',
      titleEn: 'Driver home / offline',
      descriptionAr: 'ملخص مباشر لحساب السائق والشحنات والمحفظة وحالة التشغيل.',
      sources: [
        ReferenceDataSource.driver,
        ReferenceDataSource.shipments,
        ReferenceDataSource.wallet,
      ],
    ),
    ReferenceScreenSpec(
      number: 4,
      titleAr: 'قائمة الطلبات',
      titleEn: 'Orders list',
      descriptionAr: 'الشحنات الحقيقية المخصصة للسائق من السيرفر.',
      sources: [ReferenceDataSource.shipments],
    ),
    ReferenceScreenSpec(
      number: 5,
      titleAr: 'تفاصيل الطلب',
      titleEn: 'Order detail',
      descriptionAr: 'تفاصيل أول شحنة حقيقية متاحة للسائق ومواقعها ورسومها.',
      sources: [ReferenceDataSource.shipmentDetail],
      unsupported: [
        'تفاصيل أصناف الطلب ليست ضمن استجابة Shipment الحالية للسائق.',
      ],
    ),
    ReferenceScreenSpec(
      number: 6,
      titleAr: 'الملاحة إلى نقطة الاستلام',
      titleEn: 'Navigation to pickup',
      descriptionAr: 'إحداثيات المتجر والعميل وآخر موقع للسائق وبيانات التتبع.',
      sources: [ReferenceDataSource.tracking],
      unsupported: [
        'السيرفر يعيد الإحداثيات والتتبع لكنه لا يعيد تعليمات turn-by-turn؛ الملاحة التفصيلية تعتمد مزود الخرائط على الجهاز.',
      ],
    ),
    ReferenceScreenSpec(
      number: 7,
      titleAr: 'التحقق من الاستلام',
      titleEn: 'Pickup verification',
      descriptionAr: 'تأكيد استلام الشحنة عبر مسار pickup الحقيقي في السيرفر.',
      sources: [ReferenceDataSource.shipmentDetail],
      actions: [ReferenceAction.pickupShipment],
      unsupported: [
        'قائمة فحص الأصناف التفصيلية غير ممثلة في Shipment schema الحالي.',
        'صور إثبات الاستلام ليست حقولاً مدعومة في مسار pickup الحالي.',
      ],
    ),
    ReferenceScreenSpec(
      number: 8,
      titleAr: 'تسليم الطلب للعميل',
      titleEn: 'Delivery handoff',
      descriptionAr: 'تسليم الشحنة فعلياً وتحديث حالتها عبر السيرفر.',
      sources: [ReferenceDataSource.shipmentDetail],
      actions: [ReferenceAction.deliverShipment],
      unsupported: [
        'توقيع العميل غير مدعوم في مسار deliver الحالي.',
        'صورة إثبات التسليم غير مدعومة في مسار deliver الحالي.',
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
      titleAr: 'المحفظة والتحويل',
      titleEn: 'Wallet payout',
      descriptionAr: 'عرض الرصيد والحركات الحقيقية مع إبقاء التحويل ظاهراً حتى يدعمه السيرفر.',
      sources: [
        ReferenceDataSource.wallet,
        ReferenceDataSource.walletTransactions,
      ],
      unsupported: [
        'لا يوجد endpoint لسحب أرباح السائق أو إنشاء payout بنكي.',
        'لا توجد حالة payout أو مرجع تحويل بنكي للسائق في API الحالي.',
      ],
    ),
    ReferenceScreenSpec(
      number: 11,
      titleAr: 'مركز الإشعارات',
      titleEn: 'Notifications',
      descriptionAr: 'إشعارات الحساب الفعلية القادمة من Notifications API.',
      sources: [ReferenceDataSource.notifications],
    ),
    ReferenceScreenSpec(
      number: 12,
      titleAr: 'الملف الشخصي والإعدادات',
      titleEn: 'Profile settings',
      descriptionAr: 'بيانات السائق وحالته واعتماده وتقييمه من Drivers API.',
      sources: [ReferenceDataSource.driver],
      unsupported: [
        'تعديل السائق لنفسه غير متاح بمسار self-service؛ PUT Drivers يتطلب صلاحية users.edit.',
      ],
    ),
    ReferenceScreenSpec(
      number: 13,
      titleAr: 'تسجيل سائق جديد',
      titleEn: 'Driver registration',
      descriptionAr: 'حقول التسجيل المرجعية تبقى ظاهرة مع بيان ما ينقص السيرفر.',
      sources: [ReferenceDataSource.driver],
      unsupported: [
        'إنشاء Driver موجود إدارياً لكنه يتطلب users.create؛ لا يوجد تسجيل ذاتي للسائق.',
        'رفع هوية السائق أثناء التسجيل غير متاح كمسار public/self-service.',
        'رفع رخصة القيادة أثناء التسجيل غير متاح كمسار public/self-service.',
      ],
    ),
    ReferenceScreenSpec(
      number: 14,
      titleAr: 'وثائق المركبة والسائق',
      titleEn: 'Vehicle documents',
      descriptionAr: 'حالة التحقق من السائق وتسجيل وتأمين المركبة الفعليين.',
      sources: [ReferenceDataSource.driver, ReferenceDataSource.vehicle],
      unsupported: [
        'لا يوجد workflow للسائق لرفع وثائق الهوية ومتابعة مراجعتها من التطبيق.',
        'لا يوجد رفع ذاتي لرخصة/استمارة المركبة أو وثيقة التأمين من تطبيق السائق.',
      ],
    ),
    ReferenceScreenSpec(
      number: 15,
      titleAr: 'ملف المركبة',
      titleEn: 'Vehicle profile',
      descriptionAr: 'المركبة الحالية المسندة للسائق وبياناتها الحقيقية.',
      sources: [ReferenceDataSource.vehicle],
      unsupported: [
        'سجل الصيانة ومواعيد الخدمة الدورية غير موجودين كـ driver self-service endpoints.',
      ],
    ),
    ReferenceScreenSpec(
      number: 16,
      titleAr: 'جدول التوفر',
      titleEn: 'Availability schedule',
      descriptionAr: 'تعرض حالة التشغيل وقبول الطلبات الحقيقية مع حقول الجدول المرجعية.',
      sources: [ReferenceDataSource.driver],
      unsupported: [
        'لا يوجد endpoint لأيام توفر أسبوعية للسائق.',
        'لا توجد حقول وقت بداية ونهاية دوام يومي للسائق.',
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
        'لا يوجد كيان أو endpoint لبرنامج حوافز السائق.',
        'لا توجد أهداف/تقدم/قيمة مكافأة مستحقة محفوظة للسائق.',
      ],
    ),
    ReferenceScreenSpec(
      number: 18,
      titleAr: 'مشكلة في الطلب',
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
      titleAr: 'محادثة العميل',
      titleEn: 'Customer chat',
      descriptionAr: 'محادثات الحساب الحقيقية وعدد الرسائل غير المقروءة من Chats API.',
      sources: [ReferenceDataSource.chats],
    ),
    ReferenceScreenSpec(
      number: 20,
      titleAr: 'المساعدة الطارئة',
      titleEn: 'Emergency assistance',
      descriptionAr: 'الأسئلة الشائعة والتذاكر كقنوات دعم مدعومة من السيرفر.',
      sources: [
        ReferenceDataSource.supportFaqs,
        ReferenceDataSource.supportTickets,
      ],
      unsupported: [
        'زر SOS جغرافي مخصص للطوارئ غير موجود في API الحالي.',
        'رقم/جهة طوارئ ديناميكية من السيرفر غير متاحة حالياً.',
      ],
    ),
    ReferenceScreenSpec(
      number: 21,
      titleAr: 'مركز الدعم',
      titleEn: 'Support center',
      descriptionAr: 'FAQ والتذاكر الفعلية من مركز الدعم.',
      sources: [
        ReferenceDataSource.supportFaqs,
        ReferenceDataSource.supportTickets,
      ],
    ),
    ReferenceScreenSpec(
      number: 22,
      titleAr: 'التقييم والملاحظات',
      titleEn: 'Rating feedback',
      descriptionAr: 'متوسط وعدد تقييمات السائق الحقيقيين من Driver DTO.',
      sources: [ReferenceDataSource.driver],
      unsupported: [
        'Reviews API الحالي خاص بالمنتجات وليس بالسائق؛ لا توجد قائمة تعليقات تقييم السائق.',
      ],
    ),
    ReferenceScreenSpec(
      number: 23,
      titleAr: 'لا توجد طلبات',
      titleEn: 'Empty orders',
      descriptionAr: 'حالة القائمة الفارغة مبنية فوق قائمة الشحنات الحقيقية؛ إذا أعاد السيرفر عناصر تظهر بياناتها بدلاً من اختلاق فراغ.',
      sources: [ReferenceDataSource.shipments],
    ),
    ReferenceScreenSpec(
      number: 24,
      titleAr: 'إحالة صديق',
      titleEn: 'Refer a friend',
      descriptionAr: 'واجهة الإحالة المرجعية موجودة من دون اختلاق كود أو مكافأة.',
      sources: [ReferenceDataSource.driver],
      unsupported: [
        'لا يوجد referralCode للسائق في API الحالي.',
        'لا يوجد رابط دعوة أو قائمة محالين.',
        'لا توجد مكافأة إحالة محفوظة في السيرفر.',
      ],
    ),
    ReferenceScreenSpec(
      number: 25,
      titleAr: 'سجل الرحلات',
      titleEn: 'Trip history',
      descriptionAr: 'سجل الشحنات الحقيقي وحالاتها وتواريخها من السيرفر.',
      sources: [ReferenceDataSource.shipments],
    ),
    ReferenceScreenSpec(
      number: 26,
      titleAr: 'مسح رمز QR',
      titleEn: 'QR scan',
      descriptionAr: 'واجهة المسح والأصل المرجعي موجودان مع توضيح نقص مسار التحقق.',
      sources: [ReferenceDataSource.shipmentDetail],
      unsupported: [
        'لا يوجد endpoint للتحقق من QR خاص بالشحنة.',
        'لا يوجد token/نتيجة QR في Shipment schema الحالي.',
      ],
    ),
    ReferenceScreenSpec(
      number: 27,
      titleAr: 'الطلبات المجمّعة',
      titleEn: 'Batch orders',
      descriptionAr: 'تعرض الشحنات الفعلية التي يمكن للسائق تنفيذها، دون اختلاق تجميع غير موجود.',
      sources: [ReferenceDataSource.shipments],
      unsupported: [
        'لا يوجد كيان Batch Assignment يربط عدة شحنات كحزمة واحدة.',
        'لا يوجد ترتيب مسار batch محفوظ من السيرفر.',
      ],
    ),
    ReferenceScreenSpec(
      number: 28,
      titleAr: 'فحص محتويات الاستلام',
      titleEn: 'Pickup inventory',
      descriptionAr: 'تعرض بيانات الشحنة مع عناصر الفحص المرجعية كاملة.',
      sources: [ReferenceDataSource.shipmentDetail],
      unsupported: [
        'قائمة أصناف الشحنة التفصيلية ليست ضمن Shipment DTO الحالي.',
        'نتيجة فحص الحرارة غير ممثلة في Shipment schema.',
        'صور الفحص غير مدعومة.',
        'النواقص والتلف كعناصر فحص مستقلة غير مدعومة.',
      ],
    ),
    ReferenceScreenSpec(
      number: 29,
      titleAr: 'إثبات التسليم',
      titleEn: 'Delivery proof',
      descriptionAr: 'تعرض حالة الشحنة وموقعها وتبقي حقول الإثبات واضحة.',
      sources: [
        ReferenceDataSource.shipmentDetail,
        ReferenceDataSource.tracking,
      ],
      unsupported: [
        'صورة إثبات التسليم غير مدعومة في endpoint deliver الحالي.',
        'توقيع العميل غير مدعوم.',
        'اسم مستلم موثق/مرجع POD غير موجودين في Shipment DTO الحالي.',
      ],
    ),
    ReferenceScreenSpec(
      number: 30,
      titleAr: 'تعديل الحساب البنكي',
      titleEn: 'Bank account edit',
      descriptionAr: 'تعرض رقم حساب المحفظة الحقيقي مع جميع حقول البنك المرجعية كفجوات معلنة.',
      sources: [ReferenceDataSource.wallet],
      unsupported: [
        'لا توجد BankAccount entity/endpoint للسائق.',
        'اسم البنك غير محفوظ ضمن ملف السائق/المحفظة.',
        'اسم صاحب الحساب البنكي غير مدعوم.',
        'IBAN/رقم الحساب البنكي غير مدعوم.',
      ],
    ),
    ReferenceScreenSpec(
      number: 31,
      titleAr: 'اللغة والخصوصية',
      titleEn: 'Language & privacy',
      descriptionAr: 'إعدادات واجهة محلية مع معلومات الحساب الحقيقية.',
      sources: [ReferenceDataSource.driver],
      unsupported: [
        'تفضيل اللغة غير محفوظ في ملف السائق على السيرفر حالياً.',
        'تفضيلات الخصوصية ليست لها حقول/endpoint مخصص.',
      ],
    ),
    ReferenceScreenSpec(
      number: 32,
      titleAr: 'لوحة الأداء',
      titleEn: 'Performance dashboard',
      descriptionAr: 'تعرض التقييم والشحنات والأرصدة الفعلية كمؤشرات أداء متاحة.',
      sources: [
        ReferenceDataSource.driver,
        ReferenceDataSource.shipments,
        ReferenceDataSource.wallet,
      ],
      unsupported: [
        'لا يوجد endpoint مخصص لمؤشرات أداء محسوبة مثل نسبة القبول أو الالتزام بالوقت.',
        'لا توجد أهداف أداء دورية محفوظة للسائق.',
      ],
    ),
    ReferenceScreenSpec(
      number: 33,
      titleAr: 'تفصيل تقييم السائق',
      titleEn: 'Driver rating breakdown',
      descriptionAr: 'تعرض المتوسط والعدد الحقيقيين دون إنشاء توزيع أو تعليقات وهمية.',
      sources: [ReferenceDataSource.driver],
      unsupported: [
        'لا يوجد توزيع نجوم 1–5 للسائق في API الحالي.',
        'لا توجد تعليقات customer-to-driver أو تقييمات رحلة مفصلة.',
      ],
    ),
    ReferenceScreenSpec(
      number: 34,
      titleAr: 'تفضيلات الإشعارات',
      titleEn: 'Notification preferences',
      descriptionAr: 'تعرض الإشعارات الفعلية مع خيارات التفضيل المرجعية كاملة.',
      sources: [ReferenceDataSource.notifications],
      unsupported: [
        'لا يوجد endpoint لحفظ تفضيلات أنواع إشعارات السائق.',
        'لا توجد ساعات كتم/quiet hours محفوظة في السيرفر.',
      ],
    ),
    ReferenceScreenSpec(
      number: 35,
      titleAr: 'منطقة الخدمة',
      titleEn: 'Service area',
      descriptionAr: 'مناطق التوصيل الفعلية من DeliveryZones API.',
      sources: [ReferenceDataSource.deliveryZones],
      unsupported: [
        'لا يوجد ربط في Driver يحدد مناطق خدمة السائق المفضلة أو المسموح بها.',
      ],
    ),
    ReferenceScreenSpec(
      number: 36,
      titleAr: 'حالة النظام',
      titleEn: 'System status',
      descriptionAr: 'تعرض نجاح الاتصال بمصدر حساب السائق من دون اختلاق uptime.',
      sources: [ReferenceDataSource.driver],
      unsupported: [
        'لا يوجد endpoint مخصص لحالة الخدمات/uptime.',
        'لا يوجد feed لحوادث النظام أو الصيانة المجدولة.',
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
        'Shipment list لا يعيد مبلغ COD المطلوب تحصيله كسجل مستقل للسائق.',
        'لا يوجد سجل تسوية cash collection خاص بالسائق.',
      ],
    ),
    ReferenceScreenSpec(
      number: 38,
      titleAr: 'نجاح التحويل',
      titleEn: 'Payout success',
      descriptionAr: 'تعرض المحفظة والمعاملات الحقيقية وتبقي نتيجة التحويل المرجعية واضحة.',
      sources: [
        ReferenceDataSource.wallet,
        ReferenceDataSource.walletTransactions,
      ],
      unsupported: [
        'لا يوجد payout للسائق، لذلك لا توجد عملية تحويل ناجحة حقيقية يمكن عرضها.',
        'لا يوجد payoutId أو bank reference أو حالة تحويل بنكي.',
      ],
    ),
    ReferenceScreenSpec(
      number: 39,
      titleAr: 'إرجاع الطلب',
      titleEn: 'Return order',
      descriptionAr: 'تعرض الشحنة الحقيقية وتُبقي مهمة المرتجع كسير عمل غير مدعوم بدلاً من خلط مرتجعات العميل بمهام السائق.',
      sources: [ReferenceDataSource.shipmentDetail],
      unsupported: [
        'Returns API الحالي موجّه لطلبات إرجاع العميل صاحب الحساب ولا يمثل قائمة مهام السائق.',
        'لا يوجد endpoint يعيد مرتجعات مسندة للسائق أو workflow خاص بالسائق لاستلام/إعادة مرتجع.',
      ],
    ),
    ReferenceScreenSpec(
      number: 40,
      titleAr: 'تعذر الوصول للعميل',
      titleEn: 'Customer unavailable',
      descriptionAr: 'الموقع والتتبع الحقيقيان مع إمكانية تسجيل فشل التسليم وسببه.',
      sources: [
        ReferenceDataSource.shipmentDetail,
        ReferenceDataSource.tracking,
      ],
      actions: [ReferenceAction.failShipment],
      unsupported: [
        'ملاحظات محاولة الاتصال/عدد المكالمات ليست حقولاً مستقلة في Shipment DTO.',
      ],
    ),
    ReferenceScreenSpec(
      number: 41,
      titleAr: 'ملخص الوردية',
      titleEn: 'Shift summary',
      descriptionAr: 'ملخص من بيانات السائق والشحنات والمحفظة والمعاملات الحقيقية.',
      sources: [
        ReferenceDataSource.driver,
        ReferenceDataSource.shipments,
        ReferenceDataSource.wallet,
        ReferenceDataSource.walletTransactions,
      ],
      unsupported: [
        'لا يوجد Shift entity أو endpoint لبدء/إغلاق وردية السائق.',
        'لا توجد تسوية وردية محفوظة في السيرفر.',
      ],
    ),
    ReferenceScreenSpec(
      number: 42,
      titleAr: 'صيانة المركبة',
      titleEn: 'Vehicle maintenance',
      descriptionAr: 'بيانات المركبة الحالية: النوع واللوحة والطراز والتأمين والتسجيل.',
      sources: [ReferenceDataSource.vehicle],
      unsupported: [
        'لا يوجد سجل صيانة للمركبة متاح للسائق.',
        'لا توجد مواعيد خدمة/عداد صيانة في Vehicles API الحالي.',
      ],
    ),
    ReferenceScreenSpec(
      number: 43,
      titleAr: 'انتهاء الوثائق',
      titleEn: 'Document expiry',
      descriptionAr: 'تعرض تواريخ انتهاء تسجيل وتأمين المركبة وحالة السائق.',
      sources: [ReferenceDataSource.vehicle, ReferenceDataSource.driver],
      unsupported: [
        'لا يوجد طلب تجديد ذاتي من تطبيق السائق.',
        'لا يوجد رفع مستند تجديد جديد عبر Vehicles/Drivers self-service API.',
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
      descriptionAr: 'قائمة التذاكر الحقيقية مع إمكانية إنشاء شكوى فعلية من نفس الشاشة.',
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
        'عمولة المنصة كعنصر مستقل غير موجودة في Shipment DTO الحالي.',
        'الضريبة كعنصر مستقل غير موجودة في Shipment DTO الحالي.',
        'الحوافز كعنصر مستقل ضمن تفاصيل رسوم الرحلة غير مدعومة.',
      ],
    ),
    ReferenceScreenSpec(
      number: 47,
      titleAr: 'التحقق من الهوية',
      titleEn: 'Identity verification',
      descriptionAr: 'IsVerified وApprovalStatus الفعليان من ملف السائق.',
      sources: [ReferenceDataSource.driver],
      unsupported: [
        'لا توجد جلسة KYC ذات خطوات محفوظة في السيرفر.',
        'لا يوجد رفع صور الهوية من تطبيق السائق ومتابعة مراجعتها.',
      ],
    ),
    ReferenceScreenSpec(
      number: 48,
      titleAr: 'ملاحظات العميل',
      titleEn: 'Customer feedback',
      descriptionAr: 'تعرض متوسط وعدد تقييمات السائق الحقيقيين دون اختلاق تعليقات.',
      sources: [ReferenceDataSource.driver],
      unsupported: [
        'Reviews API الحالي خاص بالمنتجات وليس بالسائق.',
        'لا توجد تعليقات نصية من العملاء على السائق.',
        'لا توجد قائمة تقييمات رحلة-to-driver يمكن عرضها في هذه الشاشة.',
      ],
    ),
  ];

  static ReferenceScreenSpec screen(int number) => screens.firstWhere(
        (item) => item.number == number,
        orElse: () => screens.first,
      );
}
