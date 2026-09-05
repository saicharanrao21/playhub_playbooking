import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/chat_service.dart';
import '../../../../app/bootstrap/bootstrap.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  final service = ChatService();
  ref.onDispose(() => service.dispose());
  return service;
});

final chatHistoryProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, matchId) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get<Map<String, dynamic>>('/matches/$matchId/chat/messages');
  return response.isSuccess ? response.data : null;
});
