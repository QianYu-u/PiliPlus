import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/services/ai_service.dart';
import 'package:get/get.dart';

/// AI 助手控制器 - 管理每个视频的 AI 会话状态
class AiAssistantController extends GetxController {
  final String bvid;
  final int cid;

  AiAssistantController({required this.bvid, required this.cid});

  final RxBool isLoadingSubtitle = false.obs;
  final RxBool isLoadingAi = false.obs;
  final RxString subtitle = ''.obs;
  final RxString aiResponse = ''.obs;
  final RxString errorMsg = ''.obs;
  final RxInt selectedPromptIndex = 0.obs;
  final RxList<Map<String, String>> chatHistory = <Map<String, String>>[].obs;

  AiService get _aiService => AiService.to;

  @override
  void onInit() {
    super.onInit();
    _loadSubtitle();
  }

  Future<void> _loadSubtitle() async {
    if (subtitle.value.isNotEmpty) return; // 已加载过

    isLoadingSubtitle.value = true;
    errorMsg.value = '';

    final result = await _aiService.getSubtitleText(
      bvid: bvid,
      cid: cid,
    );

    isLoadingSubtitle.value = false;

    if (result case Success(:final response)) {
      subtitle.value = response;
    } else if (result case Error(:final errMsg)) {
      if (errMsg == null) {
        errorMsg.value = '当前视频没有字幕，无法使用 AI 助手';
      } else {
        errorMsg.value = errMsg;
      }
    }
  }

  Future<void> sendPrompt(String prompt) async {
    if (subtitle.value.isEmpty) {
      return;
    }

    isLoadingAi.value = true;
    aiResponse.value = '';
    errorMsg.value = '';

    final result = await _aiService.chatWithAi(
      prompt: prompt,
      content: subtitle.value,
      history: chatHistory.isNotEmpty ? chatHistory.toList() : null,
    );

    isLoadingAi.value = false;

    if (result case Success(:final response)) {
      aiResponse.value = response;
      // 添加到历史
      chatHistory.addAll([
        {'role': 'user', 'content': prompt},
        {'role': 'assistant', 'content': response},
      ]);
    } else if (result case Error(:final errMsg)) {
      errorMsg.value = errMsg ?? 'AI 请求失败';
    }
  }

  void resetConversation() {
    chatHistory.clear();
    aiResponse.value = '';
    errorMsg.value = '';
  }

  void retryLoadSubtitle() {
    subtitle.value = '';
    _loadSubtitle();
  }
}
