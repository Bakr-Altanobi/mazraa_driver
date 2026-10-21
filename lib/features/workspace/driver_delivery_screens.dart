import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart' hide GeoPoint;
import 'package:url_launcher/url_launcher.dart';
import 'package:mazraa_driver/core/models/app_models.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'package:mazraa_driver/features/shipments/shipment_providers.dart';
import 'package:mazraa_driver/features/shipments/driver_location_session.dart';
import 'package:mazraa_driver/features/shipments/shipment_handoff_dialogs.dart';
import 'package:mazraa_driver/shared/widgets/map_panel.dart';
import 'package:mazraa_driver/shared/widgets/mazraa_widgets.dart';
import 'driver_tool_screens.dart';
import 'driver_workspace_repository.dart';

class DriverTaskPickerScreen extends ConsumerWidget {
  const DriverTaskPickerScreen({
    required this.task,
    this.history = false,
    super.key,
  });
  final String task;
  final bool history;
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final state = ref.watch(shipmentsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          toolText(
            c,
            history ? 'سجل الشحنات' : 'اختر الشحنة',
            history ? 'Delivery history' : 'Select shipment',
          ),
        ),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(shipmentsProvider),
        ),
        data: (rows) {
          final items = rows
              .where(
                (s) => history
                    ? s.status.isClosed
                    : task == 'pickup'
                    ? s.status == ShipmentStatus.accepted ||
                          s.status == ShipmentStatus.pickedUp
                    : task == 'qr'
                    ? s.status == ShipmentStatus.nearCustomer
                    : task == 'fees' || task == 'proofs' || task == 'details'
                    ? true
                    : s.status.isActive,
              )
              .toList();
          if (items.isEmpty)
            return EmptyState(
              title: toolText(c, 'لا توجد شحنة مؤهلة', 'No eligible shipment'),
              message: toolText(
                c,
                'ستظهر المهام المناسبة هنا عند إسنادها إليك.',
                'Eligible assigned tasks will appear here.',
              ),
            );
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(shipmentsProvider);
              await ref.read(shipmentsProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: items.length,
              itemBuilder: (c, i) {
                final s = items[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.local_shipping_outlined),
                      title: Text(s.number),
                      subtitle: Text(
                        '${s.status.label(isArabic(c))} · #${s.orderId}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => c.push(
                        history || task == 'details' || task == 'delivery'
                            ? '/shipments/${s.id}'
                            : '/shipments/${s.id}/$task',
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Google encoded polylines are drawn only for successful road-route responses.
/// Enforces bounded, finite coordinates before handing them to the native map.
List<GeoPoint> decodeRoadPolyline(String encoded) {
  if (encoded.length > 200000)
    throw const FormatException('Route is too large');
  final points = <GeoPoint>[];
  int index = 0, lat = 0, lng = 0;
  int next() {
    int result = 0, shift = 0, b;
    do {
      if (index >= encoded.length || shift > 30)
        throw const FormatException('Invalid route');
      b = encoded.codeUnitAt(index++) - 63;
      if (b < 0 || b > 63) throw const FormatException('Invalid route');
      result |= (b & 31) << shift;
      shift += 5;
    } while (b >= 32);
    return (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
  }

  while (index < encoded.length) {
    lat += next();
    lng += next();
    final a = lat / 1e5, b = lng / 1e5;
    if (a.abs() > 90 || b.abs() > 180)
      throw const FormatException('Invalid route location');
    points.add(GeoPoint(a, b));
  }
  return points;
}

final shipmentRoadProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, key) async {
      final parts = key.split(':');
      return ref
          .watch(apiClientProvider)
          .get<Map<String, dynamic>>(
            'api/Shipments/${parts[0]}/road-route',
            queryParameters: {'to': parts[1]},
          );
    });
final shipmentProofsProvider = FutureProvider.autoDispose
    .family<List<dynamic>, int>(
      (ref, id) => ref
          .watch(apiClientProvider)
          .get<List<dynamic>>('api/Shipments/$id/proofs'),
    );
final shipmentContactsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>(
      (ref, id) => ref
          .watch(apiClientProvider)
          .get<Map<String, dynamic>>(
            'api/driver-journey/shipments/$id/contacts',
          ),
    );
final waitingSinceProvider = StateProvider.family<DateTime?, int>(
  (ref, id) => null,
);

class DriverShipmentToolScreen extends ConsumerStatefulWidget {
  const DriverShipmentToolScreen({
    required this.shipmentId,
    required this.tool,
    super.key,
  });
  final int shipmentId;
  final String tool;
  @override
  ConsumerState<DriverShipmentToolScreen> createState() =>
      _DriverShipmentToolScreenState();
}

class _DriverShipmentToolScreenState
    extends ConsumerState<DriverShipmentToolScreen> {
  bool _busy = false;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    if (widget.tool == 'unavailable')
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checklist() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final api = ref.read(driverApiProvider);
      final manifest = await api.getShipmentManifest(widget.shipmentId);
      final saved = await api.getPickupChecklist(widget.shipmentId);
      if (!mounted) return;
      if (saved['submitted'] == true) {
        await showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(
              toolText(
                c,
                'قائمة الاستلام المسجلة',
                'Recorded pickup checklist',
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final line in recordRows(
                    recordMap(saved['checklist'])['lines'],
                  ))
                    Text(
                      '${line['orderItemId']}: ${toolText(c, 'مستلم', 'Received')} ${line['receivedQuantity']} · ${toolText(c, 'ناقص', 'Missing')} ${line['missingQuantity']} · ${toolText(c, 'تالف', 'Damaged')} ${line['damagedQuantity']}',
                    ),
                  Text(
                    toolText(
                      c,
                      'القائمة محفوظة ولا يمكن استبدالها. تواصل مع الدعم عند وجود اختلاف.',
                      'This checklist is immutable. Contact support for discrepancies.',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(toolText(c, 'إغلاق', 'Close')),
              ),
            ],
          ),
        );
        return;
      }
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => PickupChecklistDialog(manifest: manifest),
      );
      if (result != null) {
        await api.submitPickupChecklist(widget.shipmentId, result);
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                toolText(
                  context,
                  'حُفظت قائمة الاستلام. انتقل لتفاصيل الشحنة لإكمال الخطوة.',
                  'Pickup checklist saved. Continue in shipment details.',
                ),
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

  @override
  Widget build(BuildContext c) {
    final state = ref.watch(shipmentDetailsProvider(widget.shipmentId));
    final title = switch (widget.tool) {
      'contacts' => toolText(c, 'التواصل والاتصال', 'Contacts & calls'),
      'navigation' => toolText(c, 'الملاحة والمسار', 'Navigation & route'),
      'pickup' => toolText(c, 'فحص الاستلام', 'Pickup checklist'),
      'fees' => toolText(c, 'تفاصيل رسوم الشحنة', 'Shipment fee breakdown'),
      'unavailable' => toolText(
        c,
        'تعذر الوصول للعميل',
        'Customer unavailable',
      ),
      _ => toolText(c, 'إثباتات الشحنة', 'Shipment proofs'),
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () =>
              ref.invalidate(shipmentDetailsProvider(widget.shipmentId)),
        ),
        data: (s) {
          final pickup =
              s.status == ShipmentStatus.assigned ||
              s.status == ShipmentStatus.accepted;
          final roadKey = '${s.id}:${pickup ? 'pickup' : 'customer'}';
          final road = widget.tool == 'navigation'
              ? ref.watch(shipmentRoadProvider(roadKey))
              : null;
          List<GeoPoint> route = [];
          final roadData = road?.valueOrNull;
          if (roadData?['isRoadRoute'] == true &&
              roadData?['encodedPolyline'] is String) {
            try {
              route = decodeRoadPolyline(
                roadData!['encodedPolyline'] as String,
              );
            } catch (_) {}
          }
          final since = ref.watch(waitingSinceProvider(s.id));
          final elapsed = since == null
              ? Duration.zero
              : DateTime.now().difference(since);
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text(s.number, style: Theme.of(c).textTheme.titleLarge),
              Text(s.status.label(isArabic(c))),
              const SizedBox(height: 14),
              if (widget.tool == 'contacts') ...[
                ref
                    .watch(shipmentContactsProvider(s.id))
                    .when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          toolText(
                            c,
                            'أرقام الاتصال غير متاحة من السيرفر حاليًا. يمكنك استخدام المحادثة أو الدعم.',
                            'Contact numbers are not available from the server yet. Use chat or support.',
                          ),
                        ),
                      ),
                      data: (contacts) => Column(
                        children: [
                          for (final who in ['customer', 'pickup'])
                            _DriverContactCard(
                              contact: recordMap(contacts[who]),
                              customer: who == 'customer',
                            ),
                        ],
                      ),
                    ),
                OutlinedButton(
                  onPressed: () => c.push('/tools/chats'),
                  child: Text(toolText(c, 'المحادثات', 'Conversations')),
                ),
                OutlinedButton(
                  onPressed: () => c.push('/support'),
                  child: Text(toolText(c, 'الدعم', 'Support')),
                ),
              ],
              if (widget.tool == 'navigation') ...[
                MapPanel(
                  driver: s.driverLocation,
                  store: s.storeLocation,
                  customer: s.customerLocation,
                  route: route,
                  height: 420,
                ),
                const SizedBox(height: 12),
                if (road?.isLoading == true) const LinearProgressIndicator(),
                if (route.isNotEmpty)
                  Text(
                    '${toolText(c, 'مسار طرق فعلي', 'Actual road route')} · ${((roadData?['distanceMeters'] as num? ?? 0) / 1000).toStringAsFixed(1)} km · ${((roadData?['durationSeconds'] as num? ?? 0) / 60).ceil()} min',
                  ),
                if (road?.hasError == true || roadData != null && route.isEmpty)
                  Text(
                    toolText(
                      c,
                      'مسار الطرق غير متاح الآن. يمكنك فتح الملاحة الخارجية إلى الإحداثيات الفعلية.',
                      'Road route is unavailable. Open external navigation to the actual coordinates.',
                    ),
                  ),
                FilledButton.icon(
                  onPressed: () async {
                    final p = pickup ? s.storeLocation : s.customerLocation;
                    if (p == null) {
                      ScaffoldMessenger.of(c).showSnackBar(
                        SnackBar(
                          content: Text(
                            toolText(
                              c,
                              'لا توجد إحداثيات للوجهة',
                              'No destination coordinates',
                            ),
                          ),
                        ),
                      );
                      return;
                    }
                    final ok = await launchUrl(
                      Uri.https('www.google.com', '/maps/dir/', {
                        'api': '1',
                        'destination': '${p.latitude},${p.longitude}',
                        'travelmode': 'driving',
                      }),
                      mode: LaunchMode.externalApplication,
                    );
                    if (!ok && c.mounted)
                      ScaffoldMessenger.of(c).showSnackBar(
                        SnackBar(
                          content: Text(
                            toolText(
                              c,
                              'تعذر فتح الملاحة',
                              'Could not open navigation',
                            ),
                          ),
                        ),
                      );
                  },
                  icon: const Icon(Icons.navigation),
                  label: Text(
                    toolText(
                      c,
                      'بدء الملاحة في Google Maps',
                      'Navigate in Google Maps',
                    ),
                  ),
                ),
              ],
              if (widget.tool == 'fees') ...[
                DriverRecordFields(
                  record: {'shipmentId': s.id, 'amount': s.deliveryFee},
                ),
                Text(
                  toolText(
                    c,
                    'رسوم التوصيل أعلاه تخص الشحنة. استحقاق السائق الفعلي يظهر في الحركات المالية عند تسويته.',
                    'The amount above is the shipment delivery fee. Driver earnings appear in the financial ledger when settled.',
                  ),
                ),
                OutlinedButton(
                  onPressed: () => c.push('/tools/earnings'),
                  child: Text(
                    toolText(c, 'الحركات المالية', 'Financial transactions'),
                  ),
                ),
              ],
              if (widget.tool == 'pickup') ...[
                FilledButton.icon(
                  onPressed: _busy ? null : _checklist,
                  icon: const Icon(Icons.checklist),
                  label: Text(
                    toolText(
                      c,
                      'فتح قائمة فحص المنتجات',
                      'Open item checklist',
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () => c.push('/shipments/${s.id}/evidence'),
                  child: Text(
                    toolText(c, 'تصوير إثبات الاستلام', 'Capture pickup proof'),
                  ),
                ),
              ],
              if (widget.tool == 'unavailable') ...[
                Text(
                  toolText(
                    c,
                    'راجع تعليمات التسليم وحاول التواصل مع العميل من خلال المحادثة. لا يتحول الطلب إلى متعذر تلقائيًا بانتهاء الانتظار.',
                    'Review instructions and contact the customer through chat. Waiting does not automatically fail the delivery.',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${elapsed.inMinutes.toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: Theme.of(c).textTheme.displayMedium,
                ),
                FilledButton(
                  onPressed: s.status.isClosed
                      ? null
                      : () =>
                            ref
                                .read(waitingSinceProvider(s.id).notifier)
                                .state = since == null
                            ? DateTime.now()
                            : null,
                  child: Text(
                    toolText(
                      c,
                      since == null ? 'بدء مؤقت الانتظار' : 'إيقاف المؤقت',
                      since == null ? 'Start waiting timer' : 'Stop timer',
                    ),
                  ),
                ),
                Text(
                  toolText(
                    c,
                    'مؤقت محلي للمساعدة، لا يفرض رسومًا أو يغيّر حالة الشحنة.',
                    'This local timer does not charge fees or change shipment state.',
                  ),
                ),
                OutlinedButton(
                  onPressed: () => c.push('/tools/chats'),
                  child: Text(toolText(c, 'المحادثات', 'Conversations')),
                ),
                OutlinedButton(
                  onPressed: () => c.push('/tools/incidents'),
                  child: Text(toolText(c, 'رفع بلاغ', 'Report an issue')),
                ),
              ],
              if (widget.tool == 'proofs') ...[
                OutlinedButton.icon(
                  onPressed:
                      (s.status != ShipmentStatus.accepted &&
                          s.status != ShipmentStatus.pickedUp &&
                          s.status != ShipmentStatus.nearCustomer)
                      ? null
                      : () => c
                            .push(
                              '/shipments/${s.id}/evidence?type=${s.status == ShipmentStatus.nearCustomer ? 1 : 0}',
                            )
                            .then(
                              (_) =>
                                  ref.invalidate(shipmentProofsProvider(s.id)),
                            ),
                  icon: const Icon(Icons.photo_camera),
                  label: Text(toolText(c, 'إضافة صورة', 'Add photo')),
                ),
                OutlinedButton.icon(
                  onPressed: s.status != ShipmentStatus.nearCustomer
                      ? null
                      : () => c
                            .push('/shipments/${s.id}/signature')
                            .then(
                              (_) =>
                                  ref.invalidate(shipmentProofsProvider(s.id)),
                            ),
                  icon: const Icon(Icons.draw),
                  label: Text(
                    toolText(c, 'توقيع المستلم', 'Recipient signature'),
                  ),
                ),
                ref
                    .watch(shipmentProofsProvider(s.id))
                    .when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => ErrorState(
                        error: e,
                        onRetry: () =>
                            ref.invalidate(shipmentProofsProvider(s.id)),
                      ),
                      data: (rows) => Column(
                        children: [
                          if (rows.isEmpty)
                            Text(
                              toolText(
                                c,
                                'لم يسجل إثبات بعد',
                                'No proof recorded yet',
                              ),
                            ),
                          for (final r in recordRows(rows))
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: DriverRecordFields(record: r),
                              ),
                            ),
                        ],
                      ),
                    ),
              ],
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => c.push('/shipments/${s.id}'),
                child: Text(
                  toolText(
                    c,
                    'تفاصيل الشحنة والخطوة التالية',
                    'Shipment details & next step',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Accept raw server tokens or a QR JSON/deep-link envelope. Verification of
/// ownership, signature, expiry and replay remains exclusively on the server.
String parseDeliveryQr(String raw, int shipmentId) {
  final value = raw.trim();
  if (value.isEmpty || value.length > 8192)
    throw const FormatException('Invalid QR');
  if (value.startsWith('{')) {
    final obj = jsonDecode(value);
    if (obj is! Map) throw const FormatException('Invalid QR');
    final id = int.tryParse('${obj['shipmentId'] ?? ''}');
    if (id != null && id != shipmentId)
      throw const FormatException(
        'الرمز لشحنة أخرى / QR belongs to another shipment',
      );
    final token = obj['qrToken'] ?? obj['token'];
    if (token is! String || token.trim().isEmpty)
      throw const FormatException('Missing QR token');
    return token.trim();
  }
  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme) {
    final id = int.tryParse(uri.queryParameters['shipmentId'] ?? '');
    if (id != null && id != shipmentId)
      throw const FormatException('QR belongs to another shipment');
    final token =
        uri.queryParameters['qrToken'] ?? uri.queryParameters['token'];
    if (token == null || token.isEmpty)
      throw const FormatException('Missing QR token');
    return token;
  }
  return value;
}

class DriverQrScannerScreen extends StatefulWidget {
  const DriverQrScannerScreen({required this.shipmentId, super.key});
  final int shipmentId;
  @override
  State<DriverQrScannerScreen> createState() => _DriverQrScannerScreenState();
}

class _DriverQrScannerScreenState extends State<DriverQrScannerScreen>
    with WidgetsBindingObserver {
  final _camera = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
    autoStart: false,
  );
  final _manual = TextEditingController();
  String? _error;
  bool _returned = false, _attached = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _attached = true;
        _start();
      }
    });
  }

  Future<void> _start() async {
    try {
      await _camera.start();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (!_attached) return;
    if (s == AppLifecycleState.resumed) {
      _start();
    } else {
      _camera.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera.dispose();
    _manual.dispose();
    super.dispose();
  }

  void _accept(String value) {
    if (_returned) return;
    try {
      final token = parseDeliveryQr(value, widget.shipmentId);
      _returned = true;
      _camera.stop();
      Navigator.pop(context, token);
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(
        toolText(c, 'مسح رمز استلام العميل', 'Scan customer delivery QR'),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 360,
            child: MobileScanner(
              controller: _camera,
              onDetect: (capture) {
                for (final b in capture.barcodes) {
                  if (b.rawValue != null) {
                    _accept(b.rawValue!);
                    break;
                  }
                }
              },
              errorBuilder: (c, e) => Center(
                child: Text(
                  toolText(
                    c,
                    'الكاميرا غير متاحة. استخدم الإدخال اليدوي أو إعدادات الأذونات.',
                    'Camera unavailable. Use manual entry or device permission settings.',
                  ),
                ),
              ),
            ),
          ),
        ),
        Text(
          toolText(
            c,
            'شحنة #${widget.shipmentId} · المسح يملأ حقل التحقق. لا يتم التسليم قبل تأكيد التحصيل وبقية الشروط.',
            'Shipment #${widget.shipmentId} · Scanning fills verification. Delivery still requires cash and handoff confirmation.',
          ),
        ),
        TextButton.icon(
          onPressed: () => _camera.toggleTorch(),
          icon: const Icon(Icons.flash_on),
          label: Text(toolText(c, 'الإضاءة', 'Flash')),
        ),
        TextField(
          controller: _manual,
          decoration: InputDecoration(
            labelText: toolText(
              c,
              'إدخال رمز QR يدويًا',
              'Enter QR token manually',
            ),
          ),
        ),
        if (_error != null)
          Text(_error!, style: TextStyle(color: Theme.of(c).colorScheme.error)),
        FilledButton(
          onPressed: () => _accept(_manual.text),
          child: Text(toolText(c, 'استخدام الرمز', 'Use token')),
        ),
      ],
    ),
  );
}

class DriverSignatureScreen extends ConsumerStatefulWidget {
  const DriverSignatureScreen({required this.shipmentId, super.key});
  final int shipmentId;
  @override
  ConsumerState<DriverSignatureScreen> createState() =>
      _DriverSignatureScreenState();
}

class _DriverSignatureScreenState extends ConsumerState<DriverSignatureScreen> {
  final _boundary = GlobalKey();
  final _name = TextEditingController();
  final _notes = TextEditingController();
  final _points = <Offset?>[];
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_name.text.trim().isEmpty || _points.whereType<Offset>().length < 10) {
      setState(
        () => _error = toolText(
          context,
          'اسم المستلم وتوقيعه مطلوبان',
          'Recipient name and signature required',
        ),
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final boundary =
          _boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) throw StateError('Signature unavailable');
      await ref
          .read(apiClientProvider)
          .post<dynamic>(
            'api/Shipments/${widget.shipmentId}/proof',
            data: {
              'type': 1,
              'recipientName': _name.text.trim(),
              'signatureData':
                  'data:image/png;base64,${base64Encode(bytes.buffer.asUint8List())}',
              'notes': _notes.text.trim(),
            },
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(toolText(c, 'توقيع المستلم', 'Recipient signature')),
    ),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        TextField(
          controller: _name,
          enabled: !_saving,
          decoration: InputDecoration(
            labelText: toolText(c, 'اسم المستلم', 'Recipient name'),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          toolText(
            c,
            'يوقّع المستلم داخل المساحة أدناه بموافقته. يُحفظ التوقيع كإثبات للشحنة.',
            'The recipient signs below with consent. The signature is stored as shipment evidence.',
          ),
        ),
        RepaintBoundary(
          key: _boundary,
          child: Container(
            height: 240,
            color: Colors.white,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: _saving
                  ? null
                  : (d) => setState(() => _points.add(d.localPosition)),
              onPanUpdate: _saving
                  ? null
                  : (d) => setState(() => _points.add(d.localPosition)),
              onPanEnd: _saving
                  ? null
                  : (_) => setState(() => _points.add(null)),
              child: CustomPaint(
                painter: _SignaturePainter(List.of(_points)),
                size: Size.infinite,
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: _saving ? null : () => setState(_points.clear),
          child: Text(toolText(c, 'مسح التوقيع', 'Clear signature')),
        ),
        TextField(
          controller: _notes,
          enabled: !_saving,
          decoration: InputDecoration(
            labelText: toolText(c, 'ملاحظات', 'Notes'),
          ),
        ),
        if (_error != null)
          Text(_error!, style: TextStyle(color: Theme.of(c).colorScheme.error)),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(toolText(c, 'حفظ التوقيع', 'Save signature')),
        ),
      ],
    ),
  );
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter(this.points);
  final List<Offset?> points;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (int i = 1; i < points.length; i++) {
      if (points[i - 1] != null && points[i] != null)
        c.drawLine(points[i - 1]!, points[i]!, p);
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => true;
}

class DriverQrDeliveryScreen extends ConsumerStatefulWidget {
  const DriverQrDeliveryScreen({required this.shipmentId, super.key});
  final int shipmentId;
  @override
  ConsumerState<DriverQrDeliveryScreen> createState() =>
      _DriverQrDeliveryScreenState();
}

class _DriverQrDeliveryScreenState
    extends ConsumerState<DriverQrDeliveryScreen> {
  bool _busy = false;
  String? _error;
  bool _done = false;
  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final api = ref.read(driverApiProvider);
      final shipment = await api.getShipment(widget.shipmentId);
      if (shipment.status != ShipmentStatus.nearCustomer)
        throw StateError(
          toolText(
            context,
            'يجب الوصول قرب العميل أولًا',
            'Mark near customer first',
          ),
        );
      final manifest = await api.getShipmentManifest(widget.shipmentId);
      if (!mounted) return;
      final result = await showDialog<DeliveryConfirmation>(
        context: context,
        builder: (_) => DeliveryConfirmationDialog(
          manifest: manifest,
          requestCode: () => api.requestDeliveryCode(widget.shipmentId),
          scanQr: () =>
              context.push<String>('/shipments/${widget.shipmentId}/scan'),
        ),
      );
      if (result == null) return;
      await api.changeShipmentStatus(
        widget.shipmentId,
        'deliver',
        numericCode: result.numericCode,
        qrToken: result.qrToken,
        cashReceivedConfirmed: result.cashConfirmed,
        cashReceivedAmount: result.cashAmount,
      );
      ref.read(driverLocationSessionProvider).disable(widget.shipmentId);
      ref.invalidate(shipmentsProvider);
      ref.invalidate(shipmentDetailsProvider(widget.shipmentId));
      ref.invalidate(shipmentTrackingProvider(widget.shipmentId));
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(toolText(c, 'التسليم برمز العميل', 'Customer code handoff')),
    ),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Icon(
          _done ? Icons.check_circle : Icons.qr_code_scanner,
          size: 80,
          color: Theme.of(c).colorScheme.primary,
        ),
        const SizedBox(height: 20),
        Text(
          toolText(
            c,
            _done
                ? 'تم تأكيد التسليم على السيرفر.'
                : 'راجع التحصيل النقدي والإثباتات، ثم امسح رمز العميل أو أدخل رمز الاستلام.',
            _done
                ? 'Delivery confirmed on the server.'
                : 'Review cash collection and proof, then scan customer QR or enter the delivery code.',
          ),
        ),
        if (_error != null)
          Text(_error!, style: TextStyle(color: Theme.of(c).colorScheme.error)),
        if (!_done)
          FilledButton(
            onPressed: _busy ? null : _confirm,
            child: Text(
              toolText(c, 'فتح تأكيد التسليم', 'Open delivery confirmation'),
            ),
          ),
        OutlinedButton(
          onPressed: () => c.push('/shipments/${widget.shipmentId}/proofs'),
          child: Text(toolText(c, 'عرض الإثباتات', 'View proofs')),
        ),
        TextButton(
          onPressed: () => c.go('/shipments/${widget.shipmentId}'),
          child: Text(toolText(c, 'تفاصيل الشحنة', 'Shipment details')),
        ),
      ],
    ),
  );
}

class _DriverContactCard extends StatelessWidget {
  const _DriverContactCard({required this.contact, required this.customer});
  final Map<String, dynamic> contact;
  final bool customer;
  @override
  Widget build(BuildContext c) {
    final phone = '${contact['phone'] ?? ''}';
    final valid = RegExp(r'^\+?[0-9][0-9 ()-]{4,24}$').hasMatch(phone);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.phone_outlined),
        title: Text(
          '${contact['name'] ?? (customer ? toolText(c, 'العميل', 'Customer') : toolText(c, 'نقطة الاستلام', 'Pickup'))}',
        ),
        subtitle: Text(
          phone.isEmpty
              ? toolText(c, 'رقم غير متاح', 'Phone unavailable')
              : phone,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.call),
          onPressed: !valid
              ? null
              : () async {
                  try {
                    final ok = await launchUrl(Uri(scheme: 'tel', path: phone));
                    if (!ok && c.mounted)
                      ScaffoldMessenger.of(c).showSnackBar(
                        SnackBar(
                          content: Text(
                            toolText(
                              c,
                              'تعذر فتح الاتصال',
                              'Could not open dialer',
                            ),
                          ),
                        ),
                      );
                  } catch (e) {
                    if (c.mounted)
                      ScaffoldMessenger.of(
                        c,
                      ).showSnackBar(SnackBar(content: Text('$e')));
                  }
                },
        ),
      ),
    );
  }
}
