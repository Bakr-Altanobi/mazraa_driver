import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/network/api_client.dart';
import 'package:mazraa_driver/core/network/providers.dart';
import 'driver_tool_catalog.dart';

final workspaceRepositoryProvider = Provider(
  (ref) => DriverWorkspaceRepository(ref.watch(apiClientProvider)),
);
final toolDataProvider = FutureProvider.autoDispose.family<dynamic, String>(
  (ref, id) => ref.watch(workspaceRepositoryProvider).load(driverTool(id)),
);

List<Map<String, dynamic>> recordRows(dynamic data) {
  final rows = data is List
      ? data
      : data is Map
      ? (data['items'] ?? data['data'])
      : null;
  return rows is List
      ? rows.whereType<Map>().map((r) => Map<String, dynamic>.from(r)).toList()
      : [];
}

Map<String, dynamic> recordMap(dynamic data) =>
    data is Map ? Map<String, dynamic>.from(data) : {};
String statusKey(dynamic s) =>
    '$s'.toLowerCase().replaceAll('_', '').replaceAll(' ', '');
String? returnAction(dynamic s) => switch (statusKey(s)) {
  '0' || 'assigned' => 'accept',
  '1' || 'accepted' => 'pickup',
  '2' || 'pickedup' => 'complete',
  _ => null,
};
String? participationAction(dynamic s) => switch (statusKey(s)) {
  'null' || '2' || 'rejected' || '3' || 'withdrawn' => 'join',
  '0' || 'requested' => 'withdraw',
  _ => null,
};

class DriverWorkspaceRepository {
  const DriverWorkspaceRepository(this.client);
  final ApiClient client;
  Future<dynamic> load(DriverTool tool) => tool.endpoint.isEmpty
      ? Future.value(<String, dynamic>{})
      : client.get<dynamic>(
          tool.endpoint,
          queryParameters: tool.id == 'earnings'
              ? {'page': 1, 'perPage': 50}
              : tool.id == 'feedback'
              ? {'page': 1, 'pageSize': 100}
              : null,
        );
  Future<void> submit(String form, Map<String, dynamic> values) async {
    final (method, path) = switch (form) {
      'availability' => ('POST', 'api/driver-journey/me/availability'),
      'preferences' => ('PUT', 'api/driver-journey/me/preferences'),
      'notifications' => (
        'PUT',
        'api/driver-journey/me/notification-preferences',
      ),
      'maintenance' => ('POST', 'api/driver-journey/vehicle-maintenance'),
      'bank' => ('PUT', 'api/driver-journey/bank-account'),
      'incident' || 'emergency' => ('POST', 'api/driver-journey/incidents'),
      'profile' => ('PUT', 'api/driver-journey/me/profile'),
      'password' => ('PUT', 'api/driver-journey/me/password'),
      'privacy' => ('PUT', 'api/driver-journey/me/privacy'),
      'deletion' => ('POST', 'api/driver-journey/me/deletion-request'),
      _ => throw ArgumentError.value(form),
    };
    if (method == 'PUT') {
      await client.put<dynamic>(path, data: values);
    } else {
      await client.post<dynamic>(path, data: values);
    }
  }

  Future<void> deleteWindow(int id) =>
      client.delete('api/driver-journey/me/availability/$id');
  Future<void> tripAction(int id, String action) async {
    await client.post<dynamic>(
      'api/driver-journey/scheduled-trips/$id/$action',
    );
  }

  Future<void> updateReturn(int id, String action) async {
    await client.post<dynamic>('api/driver-journey/returns/$id/$action');
  }
}
