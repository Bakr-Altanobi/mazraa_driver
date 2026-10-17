from pathlib import Path

catalog_path = Path('lib/features/reference_journey/reference_catalog.dart')
body_path = Path('lib/features/reference_journey/reference_production_body.dart')


def between(text, start, end, block):
    a = text.index(start)
    b = text.index(end, a)
    return text[:a] + block.rstrip() + '\n\n' + text[b:]


catalog = catalog_path.read_text()
if '  shifts,\n  shipments,' not in catalog:
    catalog = catalog.replace('  currentTrips,\n  shipments,', '  currentTrips,\n  shifts,\n  shipments,', 1)
catalog_path.write_text(catalog)

text = body_path.read_text()

text = between(text, '  List<Widget> _walletPayout', '  List<Widget> _notifications', '''  List<Widget> _walletPayout(BuildContext context, _ReferenceData data) => [
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
  ];''')

text = between(text, '  List<Widget> _vehicleDocuments', '  List<Widget> _vehicleProfile', '''  List<Widget> _vehicleDocuments(BuildContext context, _ReferenceData data) => [
    _DriverCard(driver: data.driver),
    const SizedBox(height: 10),
    _VehicleCard(vehicle: data.vehicle),
    const SizedBox(height: 10),
    _GenericList(
      title: 'وثائق السائق والمركبة',
      items: data.documents,
      preferredKeys: const ['type', 'status', 'documentNumber', 'expiresAt', 'reviewNotes'],
    ),
  ];''')

text = between(text, '  List<Widget> _vehicleProfile', '  List<Widget> _availability', '''  List<Widget> _vehicleProfile(BuildContext context, _ReferenceData data) => [
    _VehicleCard(vehicle: data.vehicle),
    const SizedBox(height: 10),
    _GenericList(
      title: 'سجل الصيانة',
      items: data.maintenance,
      preferredKeys: const ['serviceAt', 'odometerKm', 'nextServiceAt', 'nextServiceOdometerKm', 'notes'],
    ),
  ];''')

text = between(text, '  List<Widget> _availability', '  List<Widget> _incentives', '''  List<Widget> _availability(BuildContext context, _ReferenceData data) => [
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
      title: 'الورديات',
      items: data.shifts,
      preferredKeys: const ['status', 'startedAt', 'endedAt', 'completedShipments'],
    ),
  ];''')

text = between(text, '  List<Widget> _incentives', '  List<Widget> _orderIssue', '''  List<Widget> _incentives(BuildContext context, _ReferenceData data) => [
    _GenericList(
      title: 'الحوافز والمكافآت',
      items: data.incentives,
      preferredKeys: const ['title', 'targetShipments', 'rewardAmount', 'startsAt', 'endsAt'],
    ),
    const SizedBox(height: 10),
    ..._performance(context, data),
  ];''')

text = between(text, '  List<Widget> _referFriend', '  List<Widget> _tripHistory', '''  List<Widget> _referFriend(BuildContext context, _ReferenceData data) => [
    _ServerFieldCard(title: 'برنامج الإحالة', rows: {'كود الإحالة': _text(data.referral['code'])}),
    const SizedBox(height: 10),
    _GenericList(
      title: 'الإحالات',
      items: data.referralRows,
      preferredKeys: const ['referredDriverId', 'status', 'rewardAmount', 'createdAt'],
    ),
  ];''')

text = between(text, '  List<Widget> _batchOrders', '  List<Widget> _pickupInventory', '''  List<Widget> _batchOrders(BuildContext context, _ReferenceData data) => [
    _GenericList(title: 'الرحلات وتوقفاتها', items: data.currentTrips, preferredKeys: const ['trip', 'stops']),
    const SizedBox(height: 10),
    _ShipmentList(shipments: data.shipments),
  ];''')

text = between(text, '  List<Widget> _deliveryProof', '  List<Widget> _bankAccount', '''  List<Widget> _deliveryProof(BuildContext context, _ReferenceData data) => [
    ..._shipmentDetail(context, data, title: 'إثبات التسليم'),
    const SizedBox(height: 10),
    ..._navigation(context, data, destination: 'العميل'),
    const SizedBox(height: 10),
    _GenericList(
      title: 'إثباتات التسليم المسجلة',
      items: data.proofs,
      preferredKeys: const ['type', 'mediaUrl', 'signatureData', 'recipientName', 'verificationReference', 'createdAt'],
    ),
  ];''')

text = between(text, '  List<Widget> _bankAccount', '  List<Widget> _languagePrivacy', '''  List<Widget> _bankAccount(BuildContext context, _ReferenceData data) => [
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
  ];''')

text = between(text, '  List<Widget> _performance', '  List<Widget> _notificationPreferences', '''  List<Widget> _performance(BuildContext context, _ReferenceData data) {
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
  }''')

text = between(text, '  List<Widget> _payoutSuccess', '  List<Widget> _returnOrder', '''  List<Widget> _payoutSuccess(BuildContext context, _ReferenceData data) => [
    _GenericList(
      title: 'طلبات السحب والتحويل',
      items: data.payouts,
      preferredKeys: const ['amount', 'currency', 'status', 'providerReference', 'requestedAt', 'processedAt'],
    ),
    const SizedBox(height: 10),
    _ServerFieldCard(title: 'الرصيد الحالي', rows: {'الرصيد': _money(data.wallet['balance'], data.wallet['currency'])}),
  ];''')

text = between(text, '  List<Widget> _returnOrder', '  List<Widget> _customerUnavailable', '''  List<Widget> _returnOrder(BuildContext context, _ReferenceData data) => [
    _GenericList(
      title: 'مهام المرتجعات المسندة',
      items: data.returns,
      preferredKeys: const ['returnRequestId', 'status', 'assignedAt', 'acceptedAt', 'pickedUpAt', 'returnedAt'],
    ),
    const SizedBox(height: 10),
    ..._shipmentDetail(context, data, title: 'الشحنة المرتبطة'),
  ];''')

text = between(text, '  List<Widget> _shiftSummary', '  List<Widget> _vehicleMaintenance', '''  List<Widget> _shiftSummary(BuildContext context, _ReferenceData data) => [
    _GenericList(
      title: 'الورديات',
      items: data.shifts,
      preferredKeys: const ['status', 'startedAt', 'endedAt', 'completedShipments', 'startLatitude', 'startLongitude', 'endLatitude', 'endLongitude'],
    ),
    const SizedBox(height: 10),
    ..._performance(context, data),
  ];''')

text = between(text, '  List<Widget> _vehicleMaintenance', '  List<Widget> _documentExpiry', '''  List<Widget> _vehicleMaintenance(BuildContext context, _ReferenceData data) => [
    _VehicleCard(vehicle: data.vehicle),
    const SizedBox(height: 10),
    _GenericList(
      title: 'سجل الصيانة',
      items: data.maintenance,
      preferredKeys: const ['serviceAt', 'odometerKm', 'nextServiceAt', 'nextServiceOdometerKm', 'notes'],
    ),
  ];''')

text = between(text, '  List<Widget> _documentExpiry', '  List<Widget> _accountPaused', '''  List<Widget> _documentExpiry(BuildContext context, _ReferenceData data) => [
    _GenericList(
      title: 'وثائق السائق والمركبة',
      items: data.documents,
      preferredKeys: const ['type', 'status', 'documentNumber', 'expiresAt', 'reviewNotes'],
    ),
    const SizedBox(height: 10),
    _VehicleCard(vehicle: data.vehicle),
  ];''')

text = between(text, '  List<Widget> _incidentReport', '  List<Widget> _feeBreakdown', '''  List<Widget> _incidentReport(BuildContext context, _ReferenceData data) => [
    _GenericList(
      title: 'بلاغات السائق',
      items: data.incidents,
      preferredKeys: const ['category', 'title', 'description', 'isEmergency', 'status', 'createdAt'],
    ),
  ];''')

text = between(text, '  List<Widget> _identityVerification', '  List<Widget> _customerFeedback', '''  List<Widget> _identityVerification(BuildContext context, _ReferenceData data) => [
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
  ];''')

text = between(text, 'class _ReferenceData {', 'class _ReferenceHero', '''class _ReferenceData {
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
''')

a = text.index('IconData _actionIcon')
text = text[:a] + '''IconData _actionIcon(ReferenceAction action) => switch (action) {
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
'''

body_path.write_text(text)
