import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/services/ai_service.dart';
import 'package:get/get.dart';

/// AI 助手控制器 - 管理视频/专栏的 AI 会话状态
class AiAssistantController extends GetxController {
  final String? bvid;
  int? cid;
  final AiSceneType sceneType;
  final String? directContent;  // 专栏模式直接传入内容

  AiAssistantController({
    this.bvid,
    this.cid,
    this.sceneType = AiSceneType.video,
    this.directContent,
  });

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
    _loadContent();
  }

  /// 重置控制器状态（切换分 P 时调用）
  void reset() {
    subtitle.value = '';
    aiResponse.value = '';
    errorMsg.value = '';
    chatHistory.clear();
    selectedPromptIndex.value = 0;
  }

  /// 更新 CID 并重新加载字幕（仅视频模式）
  void updateCid(int newCid) {
    if (sceneType != AiSceneType.video) return;
    if (cid != newCid) {
      cid = newCid;
      reset();
      _loadContent();
    }
  }

  Future<void> _loadContent() async {
    // 专栏模式：直接使用传入内容
    if (sceneType == AiSceneType.opus && directContent != null) {
      if (directContent!.isNotEmpty) {
        subtitle.value = directContent!;
      } else {
        errorMsg.value = '无法提取文章内容';
      }
      return;
    }

    // 视频模式：获取字幕
    if (bvid == null || cid == null) {
      errorMsg.value = '缺少视频信息';
      return;
    }

    if (subtitle.value.isNotEmpty) return; // 已加载过

    isLoadingSubtitle.value = true;
    errorMsg.value = '';

    final result = await _aiService.getSubtitleText(
      bvid: bvid!,
      cid: cid!,
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
      sceneType: sceneType,
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
    _loadContent();
  }
}
