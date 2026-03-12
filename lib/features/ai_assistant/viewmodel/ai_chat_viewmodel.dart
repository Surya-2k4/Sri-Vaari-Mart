import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../model/ai_message_model.dart';
import '../service/ai_service.dart';
import '../../../core/config/ai_config.dart';
import '../../products/viewmodel/product_list_viewmodel.dart';
import '../../products/model/product_model.dart';

final aiChatViewModelProvider =
    StateNotifierProvider<AiChatViewModel, List<AiMessageModel>>((ref) {
  return AiChatViewModel(ref);
});

class AiChatViewModel extends StateNotifier<List<AiMessageModel>> {
  final Ref _ref;
  final AiService _aiService;
  final List<Map<String, String>> _history = [];

  AiChatViewModel(this._ref)
      : _aiService = AiService(AiConfig.groqApiKey),
        super([
          AiMessageModel(
            text: "Hello! I'm your Sri Vaari Mart assistant. How can I help you today?",
            role: MessageRole.assistant,
          ),
        ]);

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = AiMessageModel(text: text, role: MessageRole.user);
    state = [...state, userMessage];

    // Get current products for context
    final productState = _ref.read(productListViewModelProvider);
    final List<ProductModel> products = productState.maybeWhen(
      data: (list) => list,
      orElse: () => [],
    );

    // Call AI Service
    final response = await _aiService.getAiResponse(text, products, _history);

    // Update history
    _history.add({'role': 'user', 'content': text});
    _history.add({'role': 'assistant', 'content': response});

    final assistantMessage = AiMessageModel(
      text: response,
      role: MessageRole.assistant,
    );
    state = [...state, assistantMessage];
  }

  void clearChat() {
    _history.clear();
    state = [
      AiMessageModel(
        text: "Hello! I'm your Sri Vaari Mart assistant. How can I help you today?",
        role: MessageRole.assistant,
      ),
    ];
  }
}
