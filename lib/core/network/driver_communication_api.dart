import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazraa_driver/core/network/api_client.dart';
import 'package:mazraa_driver/core/network/providers.dart';

final driverCommunicationApiProvider = Provider<DriverCommunicationApi>(
  (ref) => DriverCommunicationApi(ref.watch(apiClientProvider)),
);

class DriverCommunicationApi {
  const DriverCommunicationApi(this._client);
  final ApiClient _client;

  Future<List<dynamic>> getFaqs({String? category, String? query}) =>
      _client.get<List<dynamic>>(
        'api/support/faqs',
        queryParameters: {
          if (category != null && category.isNotEmpty) 'category': category,
          if (query != null && query.isNotEmpty) 'q': query,
        },
      );

  Future<List<dynamic>> getTickets() =>
      _client.get<List<dynamic>>('api/support/tickets');

  Future<Map<String, dynamic>> getTicket(int id) =>
      _client.get<Map<String, dynamic>>('api/support/tickets/$id');

  Future<Map<String, dynamic>> createTicket({
    required String subject,
    required String message,
    String priority = 'normal',
  }) =>
      _client.post<Map<String, dynamic>>(
        'api/support/tickets',
        data: {
          'subject': subject.trim(),
          'message': message.trim(),
          'priority': priority,
        },
      );

  Future<Map<String, dynamic>> replyTicket(int id, String body) =>
      _client.post<Map<String, dynamic>>(
        'api/support/tickets/$id/messages',
        data: {'body': body.trim()},
      );

  Future<void> closeTicket(int id) =>
      _client.post<Object?>('api/support/tickets/$id/close');

  Future<Map<String, dynamic>> openSupportChat() =>
      _client.post<Map<String, dynamic>>('api/support/live-chat');

  Future<List<dynamic>> getChats() =>
      _client.get<List<dynamic>>('api/chats');

  Future<Map<String, dynamic>> getChat(int id) =>
      _client.get<Map<String, dynamic>>('api/chats/$id');

  Future<List<dynamic>> getChatMessages(int id) async {
    final json = await _client.get<Map<String, dynamic>>(
      'api/chats/$id/messages',
      queryParameters: const {'page': 1, 'perPage': 100},
    );
    return json['data'] as List<dynamic>? ?? const [];
  }

  Future<Map<String, dynamic>> sendChatMessage(int id, String body) =>
      _client.post<Map<String, dynamic>>(
        'api/chats/$id/messages',
        data: {'body': body.trim()},
      );
}
