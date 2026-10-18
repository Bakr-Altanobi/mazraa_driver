import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mazraa_driver/core/theme/app_theme.dart';
import 'package:mazraa_driver/features/reference_journey/reference_assets.dart';
import 'package:mazraa_driver/features/reference_journey/reference_catalog.dart';
import 'package:mazraa_driver/features/reference_journey/reference_repository.dart';

class ReferenceProductionBody extends StatelessWidget {
  const ReferenceProductionBody({
    required this.spec,
    required this.payload,
    required this.loading,
    required this.sessionReady,
    required this.actionBusy,
    required this.onAction,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final ReferenceScreenSpec spec;
  final ReferenceScreenPayload? payload;
  final bool loading;
  final bool sessionReady;
  final bool actionBusy;
  final ValueChanged<ReferenceAction> onAction;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final data = _ReferenceData(payload);
    return ListView(
      key: Key('referenceScreenContent${spec.number}'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
      children: [
        _ReferenceHero(spec: spec),
        const SizedBox(height: 16),
        if (loading) const _LoadingCard(),
        if (!sessionReady && spec.sources.isNotEmpty)
          const _NoticeCard(
            icon: Icons.lock_outline_rounded,
            title: 'يتطلب حساب سائق',
            message:
                'هذه الشاشة لا تعرض بيانات تجريبية. سجّل الدخول بحساب سائق حقيقي ليتم تحميل البيانات من السيرفر.',
          ),
        if (!loading && (sessionReady || spec.sources.isEmpty))
          ..._buildScreen(context, data),
        if (spec.actions.isNotEmpty && sessionReady) ...[
          const SizedBox(height: 16),
          _SectionTitle('إجراءات مرتبطة بالسيرفر', Icons.cloud_done_outlined),
          const SizedBox(height: 10),
          for (final action in spec.actions) ...[
            FilledButton.icon(
              onPressed: actionBusy ? null : () => onAction(action),
              icon: actionBusy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(_actionIcon(action)),
              label: Text(_actionTitle(action)),
            ),
            const SizedBox(height: 8),
          ],
        ],
        if (spec.unsupported.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionTitle('عناصر التصميم التي تنتظر دعم السيرفر', Icons.extension_off_outlined),
          const SizedBox(height: 10),
          for (final item in spec.unsupported) ...[
            _UnsupportedField(message: item),
            const SizedBox(height: 8),
          ],
        ],
        if (payload != null && payload!.results.any((item) => !item.succeeded)) ...[
          const SizedBox(height: 16),
          _SectionTitle('حالة الاتصال بالمصادر', Icons.cloud_off_outlined),
          const SizedBox(height: 10),
          for (final result in payload!.results.where((item) => !item.succeeded))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _NoticeCard(
                icon: Icons.error_outline_rounded,
                title: result.endpoint,
                message: result.error ?? 'تعذر تحميل المصدر.',
                error: true,
              ),
            ),
        ],
        const SizedBox(height: 22),
        _JourneyNavigation(
          number: spec.number,
          onPrevious: onPrevious,
          onNext: onNext,
        ),
      ],
    );
  }

  List<Widget> _buildScreen(BuildContext context, _ReferenceData data) {
    switch (spec.number) {
      case 1:
        return _onboarding(context);
      case 2:
        return _loginOtp(context);
      case 3:
        return _homeOffline(context, data);
      case 4:
        return _ordersList(context, data);
      case 5:
        return _shipmentDetail(context, data, title: 'تفاصيل الطلب');
      case 6:
        return _navigation(context, data, destination: 'نقطة الاستلام');
      case 7:
        return _pickupVerification(context, data);
      case 8:
        return _deliveryHandoff(context, data);
      case 9:
        return _earnings(context, data);
      case 10:
        return _walletPayout(context, data);
      case 11:
        return _notifications(context, data);
      case 12:
        return _profile(context, data);
      case 13:
        return _registration(context, data);
      case 14:
        return _vehicleDocuments(context, data);
      case 15:
        return _vehicleProfile(context, data);
      case 16:
        return _availability(context, data);
      case 17:
        return _incentives(context, data);
      case 18:
        return _orderIssue(context, data);
      case 19:
        return _chats(context, data);
      case 20:
        return _emergency(context, data);
      case 21:
        return _support(context, data);
      case 22:
        return _rating(context, data, breakdown: false);
      case 23:
        return _emptyOrders(context, data);
      case 24:
        return _referFriend(context, data);
      case 25:
        return _tripHistory(context, data);
      case 26:
        return _qrScan(context, data);
      case 27:
        return _batchOrders(context, data);
      case 28:
        return _pickupInventory(context, data);
      case 29:
        return _deliveryProof(context, data);
      case 30:
        return _bankAccount(context, data);
      case 31:
        return _languagePrivacy(context, data);
      case 32:
        return _performance(context, data);
      case 33:
        return _rating(context, data, breakdown: true);
      case 34:
        return _notificationPreferences(context, data);
      case 35:
        return _serviceArea(context, data);
      case 36:
        return _systemStatus(context, data);
      case 37:
        return _cashCollection(context, data);
      case 38:
        return _payoutSuccess(context, data);
      case 39:
        return _returnOrder(context, data);
      case 40:
        return _customerUnavailable(context, data);
      case 41:
        return _shiftSummary(context, data);
      case 42:
        return _vehicleMaintenance(context, data);
      case 43:
        return _documentExpiry(context, data);
      case 44:
        return _accountPaused(context, data);
      case 45:
        return _incidentReport(context, data);
      case 46:
        return _feeBreakdown(context, data);
      case 47:
        return _identityVerification(context, data);
      case 48:
        return _customerFeedback(context, data);
      default:
        return const [SizedBox.shrink()];
    }
  }

  List<Widget> _onboarding(BuildContext context) => [
        _FeatureCard(
          icon: Icons.route_rounded,
          title: 'كل رحلة في مكان واحد',
          body: 'الطلبات، التتبع، المحفظة، والمساعدة ضمن تجربة السائق.',
        ),
        const SizedBox(height: 10),
        _FeatureCard(
          icon: Icons.verified_user_outlined,
          title: 'بيانات فعلية فقط',
          body: 'بعد تسجيل الدخول يتم تحميل بيانات حساب السائق من منصة مزرعتي.',
        ),
      ];

  List<Widget> _loginOtp(BuildContext context) => const [
        _NoticeCard(
          icon: Icons.password_rounded,
          title: 'تصميم OTP محفوظ كما في المرجع',
          message:
              'السيرفر يوفّر OTP للهاتف كمسار عام، لكنه ينشئ/يستعيد حساب مستخدم عام وليس مسار دخول سائق موثّق. لذلك لا يتم ربطه كسائق بشكل خاطئ، ويظل تسجيل دخول السائق الفعلي بالبريد وكلمة المرور.',
        ),
      ];

  List<Widget> _homeOffline(BuildContext context, _ReferenceData data) {
    final driver = data.driver;
    final shipments = data.shipments;
    final wallet = data.wallet;
    return [
      _DriverCard(driver: driver),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _MetricCard(
              label: 'الشحنات',
              value: '${shipments.length}',
              icon: Icons.local_shipping_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MetricCard(
              label: 'الرصيد',
              value: _money(wallet['balance'], wallet['currency']),
              icon: Icons.account_balance_wallet_outlined,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _ServerFieldCard(
        title: 'حالة التشغيل',
        rows: {
          'الحالة': _text(driver['operationalStatus']),
          'استقبال الطلبات': _yesNo(driver['isAcceptingOrders']),
          'آخر ظهور': _date(driver['lastSeenAt']),
        },
      ),
    ];
  }

  List<Widget> _ordersList(BuildContext context, _ReferenceData data) => [
        _ShipmentList(shipments: data.shipments),
      ];

  List<Widget> _shipmentDetail(
    BuildContext context,
    _ReferenceData data, {
    required String title,
  }) {
    final shipment = data.shipmentDetail;
    if (shipment.isEmpty) return const [_EmptyServerCard('لا توجد شحنة فعلية لعرضها.')];
    return [
      _ServerFieldCard(
        title: title,
        rows: _shipmentRows(shipment),
      ),
      const SizedBox(height: 10),
      _LocationCard(shipment: shipment),
    ];
  }

  List<Widget> _navigation(
    BuildContext context,
    _ReferenceData data, {
    required String destination,
  }) {
    final tracking = data.tracking;
    final shipment = _map(tracking['shipment']);
    return [
      _RouteVisual(assets: spec.assets),
      const SizedBox(height: 12),
      _ServerFieldCard(
        title: 'الملاحة إلى $destination',
        rows: {
          'رقم الشحنة': _text(shipment['shipmentNumber']),
          'الحالة': _text(shipment['status']),
          'المسافة': _km(tracking['distanceKm']),
          'الوقت المتوقع': _minutes(tracking['etaMinutes']),
          'قناة التحديث اللحظي': _text(tracking['realtimeChannel']),
        },
      ),
    ];
  }

  List<Widget> _pickupVerification(BuildContext context, _ReferenceData data) => [
        ..._shipmentDetail(context, data, title: 'الشحنة الجاهزة للاستلام'),
        const SizedBox(height: 12),
        const _ChecklistCard(
          items: [
            ('مطابقة رقم الشحنة', null),
            ('فحص الأصناف', null),
            ('إرفاق صورة الاستلام', null),
          ],
        ),
      ];

  List<Widget> _deliveryHandoff(BuildContext context, _ReferenceData data) => [
        ..._shipmentDetail(context, data, title: 'تسليم الطلب'),
        const SizedBox(height: 12),
        const _ChecklistCard(
          items: [
            ('التحقق من الشحنة', null),
            ('توقيع العميل', null),
            ('صورة إثبات التسليم', null),
          ],
        ),
      ];

  List<Widget> _earnings(BuildContext context, _ReferenceData data) {
    final wallet = data.wallet;
    return [
      Row(
        children: [
          Expanded(
            child: _MetricCard(
              label: 'الرصيد',
              value: _money(wallet['balance'], wallet['currency']),
              icon: Icons.savings_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MetricCard(
              label: 'إيداعات الشهر',
              value: _money(wallet['monthlyCredits'], wallet['currency']),
              icon: Icons.trending_up_rounded,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _TransactionList(transactions: data.transactions),
    ];
  }

  List<Widget> _walletPayout(BuildContext context, _ReferenceData data) => [
    _ServerFieldCard(
      title: 'المحفظة',
      rows: {
        'رقم الحساب': _text(data.wallet['accountNumber']),
        'الرصيد': _money(data.wallet['balance'], data.wallet['currency']),
      },
    ),
    const SizedBox(height: 10),
    _GenericList(
      title: 'الحسابات البنكية',
      items: data.bankAccounts,
      preferredKeys: const ['bankName', 'accountHolderName', 'iban', 'accountNumber', 'isVerified', 'isDefault'],
    ),
    const SizedBox(height: 10),
    _GenericList(
      title: 'طلبات السحب',
      items: data.payouts,
      preferredKeys: const ['amount', 'currency', 'status', 'providerReference', 'requestedAt', 'processedAt'],
    ),
  ];

  List<Widget> _notifications(BuildContext context, _ReferenceData data) => [
        _NotificationList(items: data.notifications),
      ];

  List<Widget> _profile(BuildContext context, _ReferenceData data) {
    final driver = data.driver;
    return [
      _DriverCard(driver: driver),
      const SizedBox(height: 10),
      _ServerFieldCard(
        title: 'بيانات الحساب',
        rows: {
          'البريد': _text(driver['email']),
          'الهاتف': _text(driver['phone']),
          'كود السائق': _text(driver['driverCode']),
          'التحقق': _yesNo(driver['isVerified']),
          'حالة الموافقة': _text(driver['approvalStatus']),
        },
      ),
    ];
  }

  List<Widget> _registration(BuildContext context, _ReferenceData data) => [
        const _DisabledFormCard(
          title: 'طلب الانضمام كسائق',
          fields: ['الاسم الكامل', 'البريد', 'الهاتف', 'نوع المركبة', 'كلمة المرور'],
          reason:
              'إنشاء السائق موجود إدارياً فقط ويتطلب users.create؛ لا يوجد تسجيل ذاتي public للسائق.',
        ),
      ];

  List<Widget> _vehicleDocuments(BuildContext context, _ReferenceData data) => [
    _DriverCard(driver: data.driver),
    const SizedBox(height: 10),
    _VehicleCard(vehicle: data.vehicle),
    const SizedBox(height: 10),
    _GenericList(
      title: 'وثائق السائق والمركبة',
      items: data.documents,
      preferredKeys: const ['type', 'status', 'documentNumber', 'expiresAt', 'reviewNotes'],
    ),
  ];

  List<Widget> _vehicleProfile(BuildContext context, _ReferenceData data) => [
    _VehicleCard(vehicle: data.vehicle),
    const SizedBox(height: 10),
    _GenericList(
      title: 'سجل الصيانة',
      items: data.maintenance,
      preferredKeys: const ['serviceAt', 'odometerKm', 'nextServiceAt', 'nextServiceOdometerKm', 'notes'],
    ),
  ];

  List<Widget> _availability(BuildContext context, _ReferenceData data) => [
    _ServerFieldCard(
      title: 'تفضيلات قبول الرحلات',
      rows: {
        'الرحلات المجدولة': _yesNo(data.preferences['acceptScheduledTrips']),
        'التوصيل الخاص': _yesNo(data.preferences['acceptPrivateDeliveries']),
        'التوصيل المجمع': _yesNo(data.preferences['acceptBatchDeliveries']),
        'متاح للعروض': _yesNo(data.preferences['isAvailableForOffers']),
        'نطاق العروض': _km(data.preferences['offerRadiusKm']),
      },
    ),
    const SizedBox(height: 10),
    _GenericList(
      title: 'جدول التوفر الأسبوعي',
      items: data.availability,
      preferredKeys: const ['dayOfWeek', 'startTime', 'endTime', 'isActive'],
    ),
    const SizedBox(height: 10),
    _GenericList(
      title: 'الرحلات المجدولة المتاحة',
      items: data.scheduledTrips,
      preferredKeys: const ['trip', 'participation'],
    ),
    const SizedBox(height: 10),
    _GenericList(
      title: 'الورديات',
      items: data.shifts,
      preferredKeys: const ['status', 'startedAt', 'endedAt', 'completedShipments'],
    ),
  ];

  List<Widget> _incentives(BuildContext context, _ReferenceData data) => [
    _GenericList(
      title: 'الحوافز والمكافآت',
      items: data.incentives,
      preferredKeys: const ['title', 'targetShipments', 'rewardAmount', 'startsAt', 'endsAt'],
    ),
    const SizedBox(height: 10),
    ..._performance(context, data),
  ];

  List<Widget> _orderIssue(BuildContext context, _ReferenceData data) => [
        ..._shipmentDetail(context, data, title: 'الطلب المرتبط بالمشكلة'),
        const SizedBox(height: 12),
        _TicketList(tickets: data.tickets),
      ];

  List<Widget> _chats(BuildContext context, _ReferenceData data) => [
        _ChatList(chats: data.chats),
      ];

  List<Widget> _emergency(BuildContext context, _ReferenceData data) => [
        _TicketList(tickets: data.tickets),
        const SizedBox(height: 12),
        _FaqList(faqs: data.faqs),
        const SizedBox(height: 12),
        const _NoticeCard(
          icon: Icons.emergency_outlined,
          title: 'بلاغ عاجل للدعم',
          message: 'استخدم إجراء «رفع بلاغ» أدناه لإرسال بلاغ عاجل موثّق إلى منصة مزرعتي. '
              'هذه الخدمة لا تتصل بجهات الإسعاف أو الشرطة؛ في الخطر المباشر اتصل '
              'بخدمات الطوارئ المحلية بنفسك.',
        ),
      ];

  List<Widget> _support(BuildContext context, _ReferenceData data) => [
        _FaqList(faqs: data.faqs),
        const SizedBox(height: 12),
        _TicketList(tickets: data.tickets),
      ];

  List<Widget> _rating(
    BuildContext context,
    _ReferenceData data, {
    required bool breakdown,
  }) {
    final driver = data.driver;
    final avg = _double(driver['ratingAverage']);
    final count = _int(driver['ratingCount']);
    return [
      _RatingSummary(average: avg, count: count),
      if (breakdown) ...[
        const SizedBox(height: 12),
        const _DisabledFormCard(
          title: 'توزيع النجوم وتعليقات العملاء',
          fields: ['5 نجوم', '4 نجوم', '3 نجوم', '2 نجوم', 'نجمة واحدة', 'تعليقات الرحلات'],
          reason:
              'السيرفر يعيد المتوسط والعدد فقط ولا يعيد توزيع النجوم أو تعليقات customer-to-driver.',
        ),
      ],
    ];
  }

  List<Widget> _emptyOrders(BuildContext context, _ReferenceData data) {
    if (data.shipments.isEmpty) {
      return const [
        _EmptyServerCard('لا توجد شحنات في حساب السائق حالياً.'),
      ];
    }
    return [
      _NoticeCard(
        icon: Icons.info_outline_rounded,
        title: 'الحالة ليست فارغة الآن',
        message:
            'مرجع التصميم يمثل Empty State، لكن السيرفر أعاد شحنات حقيقية لذلك يتم عرضها بدلاً من اختلاق قائمة فارغة.',
      ),
      const SizedBox(height: 10),
      _ShipmentList(shipments: data.shipments),
    ];
  }

  List<Widget> _referFriend(BuildContext context, _ReferenceData data) => [
    _ServerFieldCard(title: 'برنامج الإحالة', rows: {'كود الإحالة': _text(data.referral['code'])}),
    const SizedBox(height: 10),
    _GenericList(
      title: 'الإحالات',
      items: data.referralRows,
      preferredKeys: const ['referredDriverId', 'status', 'rewardAmount', 'createdAt'],
    ),
  ];

  List<Widget> _tripHistory(BuildContext context, _ReferenceData data) => [
        _ShipmentList(shipments: data.shipments, history: true),
      ];

  List<Widget> _qrScan(BuildContext context, _ReferenceData data) => [
        _QrPanel(asset: spec.assets.isEmpty ? null : spec.assets.first.path),
        const SizedBox(height: 12),
        ..._shipmentDetail(context, data, title: 'الشحنة المراد التحقق منها'),
      ];

  List<Widget> _batchOrders(BuildContext context, _ReferenceData data) => [
    _GenericList(title: 'الرحلات وتوقفاتها', items: data.currentTrips, preferredKeys: const ['trip', 'stops']),
    const SizedBox(height: 10),
    _ShipmentList(shipments: data.shipments),
  ];

  List<Widget> _pickupInventory(BuildContext context, _ReferenceData data) => [
        ..._shipmentDetail(context, data, title: 'الاستلام والمخزون'),
        const SizedBox(height: 10),
        const _ChecklistCard(
          items: [
            ('رقم الشحنة', null),
            ('الأصناف والكميات', null),
            ('درجة الحرارة', null),
            ('النواقص والتلف', null),
          ],
        ),
      ];

  List<Widget> _deliveryProof(BuildContext context, _ReferenceData data) => [
    ..._shipmentDetail(context, data, title: 'إثبات التسليم'),
    const SizedBox(height: 10),
    ..._navigation(context, data, destination: 'العميل'),
    const SizedBox(height: 10),
    _GenericList(
      title: 'إثباتات التسليم المسجلة',
      items: data.proofs,
      preferredKeys: const ['type', 'mediaUrl', 'signatureData', 'recipientName', 'verificationReference', 'createdAt'],
    ),
  ];

  List<Widget> _bankAccount(BuildContext context, _ReferenceData data) => [
    _GenericList(
      title: 'الحسابات البنكية',
      items: data.bankAccounts,
      preferredKeys: const ['bankName', 'accountHolderName', 'iban', 'accountNumber', 'isVerified', 'isDefault'],
    ),
    const SizedBox(height: 10),
    _ServerFieldCard(
      title: 'المحفظة',
      rows: {'رقم المحفظة': _text(data.wallet['accountNumber']), 'الرصيد': _money(data.wallet['balance'], data.wallet['currency'])},
    ),
  ];

  List<Widget> _languagePrivacy(BuildContext context, _ReferenceData data) => [
        _ServerFieldCard(
          title: 'الحساب',
          rows: {
            'السائق': _text(data.driver['name']),
            'البريد': _text(data.driver['email']),
          },
        ),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const Icon(Icons.language_rounded),
            title: const Text('اللغة والمظهر'),
            subtitle: const Text('تفضيلات على الجهاز لا تحتاج بيانات خادمية.'),
            trailing: const Icon(Icons.chevron_left_rounded),
            onTap: () => context.push('/settings'),
          ),
        ),
      ];

  List<Widget> _performance(BuildContext context, _ReferenceData data) {
    final p = data.performance;
    return [
      Row(children: [
        Expanded(child: _MetricCard(label: 'التقييم', value: _double(p['ratingAverage']).toStringAsFixed(1), icon: Icons.star_outline_rounded)),
        const SizedBox(width: 8),
        Expanded(child: _MetricCard(label: 'مكتملة', value: '${_int(p['completedShipments'])}', icon: Icons.task_alt_rounded)),
        const SizedBox(width: 8),
        Expanded(child: _MetricCard(label: 'نشطة', value: '${_int(p['activeShipments'])}', icon: Icons.route_outlined)),
      ]),
      const SizedBox(height: 10),
      _ServerFieldCard(title: 'مؤشرات الأداء من السيرفر', rows: {
        'فشل التسليم': _text(p['failedShipments']),
        'نسبة قبول العروض': '${_double(p['offerAcceptanceRate']).toStringAsFixed(2)}%',
        'إجمالي العروض': _text(p['totalOffers']),
        'العروض المقبولة': _text(p['acceptedOffers']),
      }),
    ];
  }

  List<Widget> _notificationPreferences(BuildContext context, _ReferenceData data) => [
        _ServerFieldCard(
          title: 'الإشعارات الحالية',
          rows: {'عدد العناصر المحملة': '${data.notifications.length}'},
        ),
        const SizedBox(height: 10),
        const _DisabledFormCard(
          title: 'تفضيلات الإشعارات',
          fields: ['طلبات جديدة', 'تحديثات الشحنة', 'المحفظة', 'الدعم', 'ساعات الكتم'],
          reason: 'لا يوجد endpoint لحفظ تفضيلات إشعارات السائق.',
        ),
      ];

  List<Widget> _serviceArea(BuildContext context, _ReferenceData data) => [
        _GenericList(
          title: 'مناطق التوصيل من السيرفر',
          items: data.deliveryZones,
          preferredKeys: const ['name', 'cityName', 'radiusKm', 'isActive'],
        ),
      ];

  List<Widget> _systemStatus(BuildContext context, _ReferenceData data) {
    final driverSource = data.result(ReferenceDataSource.driver);
    return [
      _StatusServiceTile(
        name: 'خدمة حساب السائق',
        ok: driverSource?.succeeded == true,
        detail: driverSource?.succeeded == true
            ? 'تم الحصول على استجابة فعلية من api/Drivers.'
            : (driverSource?.error ?? 'لا توجد استجابة.'),
      ),
      const SizedBox(height: 10),
      const _NoticeCard(
        icon: Icons.monitor_heart_outlined,
        title: 'لا يتم اختلاق نسبة Uptime',
        message: 'لا يوفر السيرفر endpoint مخصصاً لحالة الخدمات أو سجل الأعطال.',
      ),
    ];
  }

  List<Widget> _cashCollection(BuildContext context, _ReferenceData data) => [
        _ShipmentList(shipments: data.shipments),
        const SizedBox(height: 10),
        _TransactionList(transactions: data.transactions),
      ];

  List<Widget> _payoutSuccess(BuildContext context, _ReferenceData data) => [
    _GenericList(
      title: 'طلبات السحب والتحويل',
      items: data.payouts,
      preferredKeys: const ['amount', 'currency', 'status', 'providerReference', 'requestedAt', 'processedAt'],
    ),
    const SizedBox(height: 10),
    _ServerFieldCard(title: 'الرصيد الحالي', rows: {'الرصيد': _money(data.wallet['balance'], data.wallet['currency'])}),
  ];

  List<Widget> _returnOrder(BuildContext context, _ReferenceData data) => [
    _GenericList(
      title: 'مهام المرتجعات المسندة',
      items: data.returns,
      preferredKeys: const ['returnRequestId', 'status', 'assignedAt', 'acceptedAt', 'pickedUpAt', 'returnedAt'],
    ),
    const SizedBox(height: 10),
    ..._shipmentDetail(context, data, title: 'الشحنة المرتبطة'),
  ];

  List<Widget> _customerUnavailable(BuildContext context, _ReferenceData data) => [
        ..._navigation(context, data, destination: 'العميل'),
        const SizedBox(height: 10),
        ..._shipmentDetail(context, data, title: 'محاولة التسليم'),
      ];

  List<Widget> _shiftSummary(BuildContext context, _ReferenceData data) => [
    _GenericList(
      title: 'الورديات',
      items: data.shifts,
      preferredKeys: const ['status', 'startedAt', 'endedAt', 'completedShipments', 'startLatitude', 'startLongitude', 'endLatitude', 'endLongitude'],
    ),
    const SizedBox(height: 10),
    ..._performance(context, data),
  ];

  List<Widget> _vehicleMaintenance(BuildContext context, _ReferenceData data) => [
    _VehicleCard(vehicle: data.vehicle),
    const SizedBox(height: 10),
    _GenericList(
      title: 'سجل الصيانة',
      items: data.maintenance,
      preferredKeys: const ['serviceAt', 'odometerKm', 'nextServiceAt', 'nextServiceOdometerKm', 'notes'],
    ),
  ];

  List<Widget> _documentExpiry(BuildContext context, _ReferenceData data) => [
    _GenericList(
      title: 'وثائق السائق والمركبة',
      items: data.documents,
      preferredKeys: const ['type', 'status', 'documentNumber', 'expiresAt', 'reviewNotes'],
    ),
    const SizedBox(height: 10),
    _VehicleCard(vehicle: data.vehicle),
  ];

  List<Widget> _accountPaused(BuildContext context, _ReferenceData data) {
    final driver = data.driver;
    return [
      _StatusServiceTile(
        name: 'حالة الحساب',
        ok: _text(driver['approvalStatus']).toLowerCase().contains('approved'),
        detail: _text(driver['approvalStatus']),
      ),
      const SizedBox(height: 10),
      _ServerFieldCard(
        title: 'تفاصيل الإيقاف من السيرفر',
        rows: {
          'نشط': _yesNo(driver['isActive']),
          'تاريخ الإيقاف': _date(driver['suspendedAt']),
          'السبب': _text(driver['suspensionReason']),
        },
      ),
    ];
  }

  List<Widget> _incidentReport(BuildContext context, _ReferenceData data) => [
    _GenericList(
      title: 'بلاغات السائق',
      items: data.incidents,
      preferredKeys: const ['category', 'title', 'description', 'isEmergency', 'status', 'createdAt'],
    ),
  ];

  List<Widget> _feeBreakdown(BuildContext context, _ReferenceData data) {
    final shipment = data.shipmentDetail;
    return [
      _ServerFieldCard(
        title: 'تفاصيل الرسوم المتاحة',
        rows: {
          'رسوم التوصيل': _money(shipment['deliveryFee'], null),
          'تكلفة النقل': _money(shipment['transportCost'], null),
          'صافي الربح': _money(shipment['netProfit'], null),
          'رقم الشحنة': _text(shipment['shipmentNumber']),
        },
      ),
      const SizedBox(height: 10),
      _TransactionList(transactions: data.transactions),
    ];
  }

  List<Widget> _identityVerification(BuildContext context, _ReferenceData data) => [
    _ServerFieldCard(title: 'حالة التحقق', rows: {
      'موثق': _yesNo(data.driver['isVerified']),
      'حالة الموافقة': _text(data.driver['approvalStatus']),
      'تاريخ الموافقة': _date(data.driver['approvedAt']),
      'كود السائق': _text(data.driver['driverCode']),
    }),
    const SizedBox(height: 10),
    _GenericList(
      title: 'الوثائق المرفوعة',
      items: data.documents,
      preferredKeys: const ['type', 'status', 'documentNumber', 'expiresAt', 'reviewNotes'],
    ),
  ];

  List<Widget> _customerFeedback(BuildContext context, _ReferenceData data) => [
        ..._rating(context, data, breakdown: true),
      ];
}

class _ReferenceData {
  const _ReferenceData(this.payload);
  final ReferenceScreenPayload? payload;

  ReferenceSourceResult? result(ReferenceDataSource source) {
    for (final row in payload?.results ?? const <ReferenceSourceResult>[]) {
      if (row.source == source) return row;
    }
    return null;
  }

  Map<String, dynamic> get journeyMe => _map(result(ReferenceDataSource.journeyMe)?.payload);
  Map<String, dynamic> get driver {
    final nested = _map(journeyMe['driver']);
    return nested.isNotEmpty ? nested : _map(result(ReferenceDataSource.driver)?.payload);
  }
  Map<String, dynamic> get preferences => _map(result(ReferenceDataSource.preferences)?.payload);
  List<Map<String, dynamic>> get availability => _listOfMaps(result(ReferenceDataSource.availability)?.payload);
  List<Map<String, dynamic>> get offers => _listOfMaps(result(ReferenceDataSource.offers)?.payload);
  List<Map<String, dynamic>> get scheduledTrips => _listOfMaps(result(ReferenceDataSource.scheduledTrips)?.payload);
  List<Map<String, dynamic>> get currentTrips => _listOfMaps(result(ReferenceDataSource.currentTrips)?.payload);
  List<Map<String, dynamic>> get shifts => _listOfMaps(result(ReferenceDataSource.shifts)?.payload);
  List<Map<String, dynamic>> get shipments => _listOfMaps(result(ReferenceDataSource.shipments)?.payload);
  Map<String, dynamic> get shipmentDetail => _map(result(ReferenceDataSource.shipmentDetail)?.payload);
  Map<String, dynamic> get tracking => _map(result(ReferenceDataSource.tracking)?.payload);
  List<Map<String, dynamic>> get proofs => _listOfMaps(result(ReferenceDataSource.shipmentProofs)?.payload);
  Map<String, dynamic> get wallet => _map(result(ReferenceDataSource.wallet)?.payload);
  List<Map<String, dynamic>> get transactions {
    final value = result(ReferenceDataSource.walletTransactions)?.payload;
    if (value is List) return _listOfMaps(value);
    final root = _map(value);
    return _listOfMaps(root['data'] ?? root['items']);
  }
  List<Map<String, dynamic>> get notifications {
    final value = result(ReferenceDataSource.notifications)?.payload;
    if (value is List) return _listOfMaps(value);
    final root = _map(value);
    return _listOfMaps(root['items'] ?? root['data']);
  }
  Map<String, dynamic> get vehicle => _map(result(ReferenceDataSource.vehicle)?.payload ?? journeyMe['vehicle']);
  List<Map<String, dynamic>> get documents => _listOfMaps(result(ReferenceDataSource.documents)?.payload);
  List<Map<String, dynamic>> get maintenance => _listOfMaps(result(ReferenceDataSource.vehicleMaintenance)?.payload);
  List<Map<String, dynamic>> get bankAccounts => _listOfMaps(result(ReferenceDataSource.bankAccounts)?.payload);
  List<Map<String, dynamic>> get payouts => _listOfMaps(result(ReferenceDataSource.payouts)?.payload);
  List<Map<String, dynamic>> get incentives => _listOfMaps(result(ReferenceDataSource.incentives)?.payload);
  Map<String, dynamic> get referral => _map(result(ReferenceDataSource.referral)?.payload);
  List<Map<String, dynamic>> get referralRows => _listOfMaps(referral['referrals']);
  List<Map<String, dynamic>> get incidents => _listOfMaps(result(ReferenceDataSource.incidents)?.payload);
  List<Map<String, dynamic>> get returns => _listOfMaps(result(ReferenceDataSource.returns)?.payload);
  Map<String, dynamic> get performance => _map(result(ReferenceDataSource.performance)?.payload);
  List<Map<String, dynamic>> get faqs => _listOfMaps(result(ReferenceDataSource.supportFaqs)?.payload);
  List<Map<String, dynamic>> get tickets => _listOfMaps(result(ReferenceDataSource.supportTickets)?.payload);
  List<Map<String, dynamic>> get chats => _listOfMaps(result(ReferenceDataSource.chats)?.payload);
  List<Map<String, dynamic>> get deliveryZones => _listOfMaps(result(ReferenceDataSource.deliveryZones)?.payload);
}

class _ReferenceHero extends StatelessWidget {
  const _ReferenceHero({required this.spec});

  final ReferenceScreenSpec spec;

  @override
  Widget build(BuildContext context) {
    final assets = spec.assets;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Color(0xFFFFFEF8), Color(0xFFF2E9D7)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (assets.isNotEmpty)
            SizedBox(
              height: 150,
              child: Image.asset(
                assets.first.path,
                fit: BoxFit.contain,
                cacheWidth: 720,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.image_not_supported_outlined,
                  size: 54,
                ),
              ),
            ),
          if (assets.length > 1) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 54,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final asset in assets.skip(1))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Container(
                        width: 54,
                        height: 54,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .85),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Image.asset(
                          asset.path,
                          fit: BoxFit.contain,
                          cacheWidth: 180,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            spec.titleAr,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: MazraaColors.forest,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            spec.titleEn,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: MazraaColors.leaf,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            spec.descriptionAr,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.driver});
  final Map<String, dynamic> driver;

  @override
  Widget build(BuildContext context) {
    if (driver.isEmpty) return const _EmptyServerCard('لم يعد السيرفر بيانات ملف السائق.');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: MazraaColors.sand,
              child: const Icon(Icons.person_rounded, size: 34, color: MazraaColors.forest),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_text(driver['name']), style: Theme.of(context).textTheme.titleLarge),
                  Text(_text(driver['driverCode']), textDirection: TextDirection.ltr),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _SmallChip(label: _text(driver['approvalStatus'])),
                      _SmallChip(label: _text(driver['operationalStatus'])),
                      _SmallChip(label: '★ ${_double(driver['ratingAverage']).toStringAsFixed(1)}'),
                    ],
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

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle});
  final Map<String, dynamic> vehicle;

  @override
  Widget build(BuildContext context) {
    if (vehicle.isEmpty) {
      return const _EmptyServerCard('لا توجد مركبة حالية مسندة لهذا السائق.');
    }
    return _ServerFieldCard(
      title: 'المركبة الحالية',
      rows: {
        'الكود': _text(vehicle['vehicleCode']),
        'النوع': _text(vehicle['vehicleType']),
        'اللوحة': _text(vehicle['plateNumber']),
        'الشركة': _text(vehicle['make']),
        'الموديل': _text(vehicle['model']),
        'السنة': _text(vehicle['year']),
        'اللون': _text(vehicle['color']),
        'الحالة': _text(vehicle['status']),
      },
    );
  }
}

class _ShipmentList extends StatelessWidget {
  const _ShipmentList({required this.shipments, this.history = false});
  final List<Map<String, dynamic>> shipments;
  final bool history;

  @override
  Widget build(BuildContext context) {
    if (shipments.isEmpty) return const _EmptyServerCard('لا توجد شحنات فعلية في الحساب حالياً.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(history ? 'سجل الرحلات' : 'الطلبات من السيرفر', Icons.local_shipping_outlined),
        const SizedBox(height: 9),
        for (final shipment in shipments) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: MazraaColors.forest.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, color: MazraaColors.forest),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _shipmentNumber(shipment),
                          textDirection: TextDirection.ltr,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text('الحالة: ${_status(shipment)}'),
                        if (shipment['createdAt'] != null)
                          Text(
                            _date(shipment['createdAt']),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  Text(_money(shipment['deliveryFee'], null)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.transactions});
  final List<Map<String, dynamic>> transactions;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) return const _EmptyServerCard('لا توجد حركات مالية فعلية لعرضها.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('الحركات المالية', Icons.receipt_long_outlined),
        const SizedBox(height: 9),
        for (final item in transactions.take(12)) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: Text(_text(item['description'] ?? item['type'])),
              subtitle: Text(_date(item['createdAt'])),
              trailing: Text(
                _money(item['amount'], null),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          const SizedBox(height: 7),
        ],
      ],
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({required this.items});
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _EmptyServerCard('لا توجد إشعارات حالياً.');
    return Column(
      children: [
        for (final item in items.take(20)) ...[
          Card(
            child: ListTile(
              leading: Icon(
                item['isRead'] == true ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                color: item['isRead'] == true ? null : MazraaColors.orange,
              ),
              title: Text(_text(item['title'])),
              subtitle: Text(
                _text(item['message']),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(_date(item['createdAt']), style: Theme.of(context).textTheme.labelSmall),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ChatList extends StatelessWidget {
  const _ChatList({required this.chats});
  final List<Map<String, dynamic>> chats;

  @override
  Widget build(BuildContext context) {
    if (chats.isEmpty) return const _EmptyServerCard('لا توجد محادثات فعلية في الحساب.');
    return Column(
      children: [
        for (final chat in chats.take(15)) ...[
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.chat_bubble_outline_rounded)),
              title: Text(_text(_map(chat['otherUser'])['name'] ?? (chat['isSupport'] == true ? 'الدعم' : 'محادثة'))),
              subtitle: Text(
                _text(_map(chat['lastMessage'])['body']),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: _SmallChip(label: '${_int(chat['unreadCount'])} جديد'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _FaqList extends StatelessWidget {
  const _FaqList({required this.faqs});
  final List<Map<String, dynamic>> faqs;

  @override
  Widget build(BuildContext context) {
    if (faqs.isEmpty) return const _EmptyServerCard('لا توجد أسئلة شائعة منشورة حالياً.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('الأسئلة الشائعة', Icons.help_outline_rounded),
        const SizedBox(height: 9),
        for (final faq in faqs.take(8))
          Card(
            child: ExpansionTile(
              title: Text(_text(faq['question'])),
              subtitle: faq['category'] == null ? null : Text(_text(faq['category'])),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [Align(alignment: AlignmentDirectional.centerStart, child: Text(_text(faq['answer'])))],
            ),
          ),
      ],
    );
  }
}

class _TicketList extends StatelessWidget {
  const _TicketList({required this.tickets});
  final List<Map<String, dynamic>> tickets;

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) return const _EmptyServerCard('لا توجد تذاكر دعم في الحساب حالياً.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('تذاكر الدعم', Icons.support_agent_rounded),
        const SizedBox(height: 9),
        for (final ticket in tickets.take(10)) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.confirmation_number_outlined),
              title: Text(_text(ticket['subject'])),
              subtitle: Text('${_text(ticket['number'])} · ${_text(ticket['status'])}'),
              trailing: _SmallChip(label: _text(ticket['priority'])),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _GenericList extends StatelessWidget {
  const _GenericList({required this.title, required this.items, required this.preferredKeys});
  final String title;
  final List<Map<String, dynamic>> items;
  final List<String> preferredKeys;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _EmptyServerCard('لا توجد عناصر فعلية ضمن $title.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(title, Icons.list_alt_rounded),
        const SizedBox(height: 9),
        for (final item in items.take(12)) ...[
          _ServerFieldCard(
            title: _text(item['name'] ?? item['number'] ?? item['id']),
            rows: {
              for (final key in preferredKeys)
                if (item.containsKey(key)) _humanKey(key): _text(item[key]),
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ServerFieldCard extends StatelessWidget {
  const _ServerFieldCard({required this.title, required this.rows});
  final String title;
  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_done_outlined, color: MazraaColors.success),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
              ],
            ),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              Text('السيرفر لم يعد حقولاً قابلة للعرض.', style: Theme.of(context).textTheme.bodyMedium)
            else
              for (final entry in rows.entries) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        entry.key,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 6,
                      child: Text(
                        entry.value,
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                if (entry.key != rows.keys.last) const Divider(height: 17),
              ],
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.shipment});
  final Map<String, dynamic> shipment;

  @override
  Widget build(BuildContext context) {
    final store = _map(shipment['storeLocation']);
    final customer = _map(shipment['customerLocation']);
    final driver = _map(shipment['driverLocation']);
    return _ServerFieldCard(
      title: 'المواقع المتاحة من السيرفر',
      rows: {
        'المتجر': _coordinates(store),
        'العميل': _coordinates(customer),
        'السائق': _coordinates(driver),
      },
    );
  }
}

class _RouteVisual extends StatelessWidget {
  const _RouteVisual({required this.assets});
  final List<ReferenceAssetSlot> assets;

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 190,
      decoration: BoxDecoration(
        color: MazraaColors.sand.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(14),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(assets.first.path, fit: BoxFit.contain, cacheWidth: 720),
          const PositionedDirectional(
            start: 14,
            bottom: 14,
            child: _SmallChip(label: 'المسار من السيرفر'),
          ),
        ],
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.average, required this.count});
  final double average;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.star_rounded, size: 52, color: MazraaColors.warning),
            const SizedBox(height: 6),
            Text(average.toStringAsFixed(1), style: Theme.of(context).textTheme.headlineLarge),
            Text('$count تقييم مسجل في ملف السائق'),
          ],
        ),
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({required this.items});
  final List<(String, bool?)> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            for (final item in items)
              CheckboxListTile(
                value: item.$2 ?? false,
                onChanged: null,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(item.$1),
                subtitle: item.$2 == null
                    ? const Text('بانتظار حقل/مسار من السيرفر')
                    : const Text('يمكن التحقق منه من بيانات الشحنة الحالية'),
              ),
          ],
        ),
      ),
    );
  }
}

class _DisabledFormCard extends StatelessWidget {
  const _DisabledFormCard({required this.title, required this.fields, required this.reason});
  final String title;
  final List<String> fields;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final field in fields) ...[
              TextField(
                enabled: false,
                decoration: InputDecoration(
                  labelText: field,
                  hintText: 'غير مدعوم من السيرفر حالياً',
                  suffixIcon: const Icon(Icons.lock_outline_rounded),
                ),
              ),
              const SizedBox(height: 10),
            ],
            _InlineUnsupported(reason),
          ],
        ),
      ),
    );
  }
}

class _InlineUnsupported extends StatelessWidget {
  const _InlineUnsupported(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: MazraaColors.warning.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: MazraaColors.warning, size: 19),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _UnsupportedField extends StatelessWidget {
  const _UnsupportedField({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: MazraaColors.warning.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MazraaColors.warning.withValues(alpha: .35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.extension_off_outlined, color: MazraaColors.warning),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon, color: MazraaColors.forest),
          title: Text(title),
          subtitle: Text(body),
        ),
      );
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.icon,
    required this.title,
    required this.message,
    this.error = false,
  });
  final IconData icon;
  final String title;
  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final color = error ? Theme.of(context).colorScheme.error : MazraaColors.forest;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyServerCard extends StatelessWidget {
  const _EmptyServerCard(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => _NoticeCard(
        icon: Icons.inbox_outlined,
        title: 'لا توجد بيانات فعلية',
        message: message,
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: MazraaColors.forest),
              const SizedBox(height: 10),
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
}

class _StatusServiceTile extends StatelessWidget {
  const _StatusServiceTile({required this.name, required this.ok, required this.detail});
  final String name;
  final bool ok;
  final String detail;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(
            ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: ok ? MazraaColors.success : MazraaColors.danger,
          ),
          title: Text(name),
          subtitle: Text(detail),
          trailing: Text(ok ? 'متاح' : 'غير متاح'),
        ),
      );
}

class _QrPanel extends StatelessWidget {
  const _QrPanel({this.asset});
  final String? asset;

  @override
  Widget build(BuildContext context) => Container(
        height: 220,
        decoration: BoxDecoration(
          color: const Color(0xFF17231B),
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.all(25),
        child: asset == null
            ? const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 100)
            : Image.asset(asset!, fit: BoxFit.contain, cacheWidth: 720),
      );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => const Card(
        child: Padding(
          padding: EdgeInsets.all(26),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.icon);
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: MazraaColors.forest),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        ],
      );
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: MazraaColors.forest.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall),
      );
}

class _JourneyNavigation extends StatelessWidget {
  const _JourneyNavigation({
    required this.number,
    required this.onPrevious,
    required this.onNext,
  });
  final int number;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPrevious,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('السابق'),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              color: MazraaColors.forest.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text('$number / 48', style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: onNext,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(number == 48 ? 'النهاية' : 'التالي'),
            ),
          ),
        ],
      );
}

Map<String, String> _shipmentRows(Map<String, dynamic> shipment) => {
      'رقم الشحنة': _shipmentNumber(shipment),
      'الحالة': _status(shipment),
      'رقم الطلب': _text(shipment['salesOrderId'] ?? shipment['orderId']),
      'رسوم التوصيل': _money(shipment['deliveryFee'], null),
      'تكلفة النقل': _money(shipment['transportCost'], null),
      'صافي الربح': _money(shipment['netProfit'], null),
      'الإنشاء': _date(shipment['createdAt']),
    };

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, item) => MapEntry(key.toString(), item));
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _listOfMaps(Object? value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value.map(_map).where((item) => item.isNotEmpty).toList(growable: false);
}

String _text(Object? value) {
  if (value == null) return 'غير متوفر';
  final text = value.toString().trim();
  return text.isEmpty ? 'غير متوفر' : text;
}

String _yesNo(Object? value) {
  if (value == null) return 'غير متوفر';
  if (value is bool) return value ? 'نعم' : 'لا';
  final normalized = value.toString().toLowerCase();
  if (normalized == 'true' || normalized == '1') return 'نعم';
  if (normalized == 'false' || normalized == '0') return 'لا';
  return _text(value);
}

String _date(Object? value) {
  if (value == null) return 'غير متوفر';
  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null) return _text(value);
  final local = parsed.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String _money(Object? amount, Object? currency) {
  final number = _double(amount);
  final code = currency == null ? '' : _text(currency);
  final value = number == number.roundToDouble() ? number.toStringAsFixed(0) : number.toStringAsFixed(2);
  return code.isEmpty || code == 'غير متوفر' ? value : '$value $code';
}


double _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _int(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _shipmentNumber(Map<String, dynamic> shipment) =>
    _text(shipment['shipmentNumber'] ?? shipment['id']);

String _status(Map<String, dynamic> shipment) => _text(shipment['status']);


String _coordinates(Map<String, dynamic> point) {
  if (point.isEmpty) return 'غير متوفر';
  final lat = point['latitude'] ?? point['lat'];
  final lng = point['longitude'] ?? point['lng'] ?? point['lon'];
  if (lat == null || lng == null) return 'غير متوفر';
  return '${_double(lat).toStringAsFixed(5)}, ${_double(lng).toStringAsFixed(5)}';
}

String _km(Object? value) => value == null ? 'غير متوفر' : '${_double(value).toStringAsFixed(1)} كم';
String _minutes(Object? value) => value == null ? 'غير متوفر' : '${_int(value)} دقيقة';

String _humanKey(String key) {
  const names = {
    'name': 'الاسم',
    'cityName': 'المدينة',
    'radiusKm': 'نطاق الخدمة',
    'isActive': 'نشط',
    'id': 'المعرف',
    'status': 'الحالة',
    'reason': 'السبب',
    'createdAt': 'الإنشاء',
  };
  return names[key] ?? key;
}

IconData _actionIcon(ReferenceAction action) => switch (action) {
      ReferenceAction.acceptShipment => Icons.check_circle_outline_rounded,
      ReferenceAction.pickupShipment => Icons.inventory_2_outlined,
      ReferenceAction.startTransit => Icons.route_outlined,
      ReferenceAction.nearCustomer => Icons.location_on_outlined,
      ReferenceAction.deliverShipment => Icons.task_alt_rounded,
      ReferenceAction.failShipment => Icons.report_problem_outlined,
      ReferenceAction.startShift => Icons.play_circle_outline_rounded,
      ReferenceAction.endShift => Icons.stop_circle_outlined,
      ReferenceAction.acceptOffer => Icons.thumb_up_alt_outlined,
      ReferenceAction.rejectOffer => Icons.thumb_down_alt_outlined,
      ReferenceAction.createIncident => Icons.support_agent_rounded,
    };

String _actionTitle(ReferenceAction action) => switch (action) {
      ReferenceAction.acceptShipment => 'قبول الشحنة على السيرفر',
      ReferenceAction.pickupShipment => 'تأكيد الاستلام على السيرفر',
      ReferenceAction.startTransit => 'بدء التوجه للعميل',
      ReferenceAction.nearCustomer => 'تأكيد الوصول قرب العميل',
      ReferenceAction.deliverShipment => 'تأكيد التسليم على السيرفر',
      ReferenceAction.failShipment => 'تسجيل تعذر التسليم',
      ReferenceAction.startShift => 'بدء الوردية',
      ReferenceAction.endShift => 'إنهاء الوردية',
      ReferenceAction.acceptOffer => 'قبول عرض التوصيل',
      ReferenceAction.rejectOffer => 'رفض عرض التوصيل',
      ReferenceAction.createIncident => 'رفع بلاغ حقيقي',
    };
