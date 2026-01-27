import 'package:PiliPlus/pages/video/ai_assistant/controller.dart';
import 'package:PiliPlus/services/ai_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:flutter_html/flutter_html.dart';

/// Markdown 转 HTML 简易工具
String _markdownToHtml(String markdown) {
  String html = markdown;

  // 转义 HTML 特殊字符（但保留我们要处理的标记）
  // 暂不转义，避免破坏 LaTeX

  // 处理代码块
  html = html.replaceAllMapped(
    RegExp(r'```(\w*)\n([\s\S]*?)```', multiLine: true),
    (match) {
      final lang = match.group(1) ?? '';
      final code = match.group(2) ?? '';
      return '<pre><code class="language-$lang">$code</code></pre>';
    },
  );

  // 处理行内代码
  html = html.replaceAllMapped(
    RegExp(r'`([^`]+)`'),
    (match) => '<code>${match.group(1)}</code>',
  );

  // 处理标题
  html = html.replaceAllMapped(
    RegExp(r'^#{6}\s+(.+)$', multiLine: true),
    (match) => '<h6>${match.group(1)}</h6>',
  );
  html = html.replaceAllMapped(
    RegExp(r'^#{5}\s+(.+)$', multiLine: true),
    (match) => '<h5>${match.group(1)}</h5>',
  );
  html = html.replaceAllMapped(
    RegExp(r'^#{4}\s+(.+)$', multiLine: true),
    (match) => '<h4>${match.group(1)}</h4>',
  );
  html = html.replaceAllMapped(
    RegExp(r'^#{3}\s+(.+)$', multiLine: true),
    (match) => '<h3>${match.group(1)}</h3>',
  );
  html = html.replaceAllMapped(
    RegExp(r'^#{2}\s+(.+)$', multiLine: true),
    (match) => '<h2>${match.group(1)}</h2>',
  );
  html = html.replaceAllMapped(
    RegExp(r'^#\s+(.+)$', multiLine: true),
    (match) => '<h1>${match.group(1)}</h1>',
  );

  // 处理粗体 **text** 或 __text__
  html = html.replaceAllMapped(
    RegExp(r'\*\*(.+?)\*\*'),
    (match) => '<strong>${match.group(1)}</strong>',
  );
  html = html.replaceAllMapped(
    RegExp(r'__(.+?)__'),
    (match) => '<strong>${match.group(1)}</strong>',
  );

  // 处理斜体 *text* 或 _text_
  html = html.replaceAllMapped(
    RegExp(r'\*([^*]+)\*'),
    (match) => '<em>${match.group(1)}</em>',
  );
  html = html.replaceAllMapped(
    RegExp(r'_([^_]+)_'),
    (match) => '<em>${match.group(1)}</em>',
  );

  // 处理无序列表
  html = html.replaceAllMapped(
    RegExp(r'^[-*+]\s+(.+)$', multiLine: true),
    (match) => '<li>${match.group(1)}</li>',
  );

  // 处理有序列表
  html = html.replaceAllMapped(
    RegExp(r'^\d+\.\s+(.+)$', multiLine: true),
    (match) => '<li>${match.group(1)}</li>',
  );

  // 处理换行
  html = html.replaceAll('\n\n', '</p><p>');
  html = '<p>$html</p>';

  // 清理多余的空段落
  html = html.replaceAll('<p></p>', '');
  html = html.replaceAll('<p>\n</p>', '');

  return html;
}

/// AI 视频助手面板
class AiAssistantPanel extends StatefulWidget {
  const AiAssistantPanel({
    super.key,
    required this.bvid,
    required this.cid,
    required this.heroTag,
  });

  final String bvid;
  final int cid;
  final String heroTag;

  /// 显示 AI 助手面板
  static void show({
    required BuildContext context,
    required String bvid,
    required int cid,
    required String heroTag,
  }) {
    final aiService = AiService.to;

    // 检查配置
    if (!aiService.isConfigured) {
      SmartDialog.showToast('请先在设置中配置 AI API');
      Get.toNamed('/aiSetting');
      return;
    }

    // 检查是否有提示词
    if (aiService.prompts.isEmpty) {
      SmartDialog.showToast('请先添加预设提示词');
      Get.toNamed('/aiSetting');
      return;
    }

    // 获取或创建控制器
    final tag = 'ai_$heroTag';
    if (!Get.isRegistered<AiAssistantController>(tag: tag)) {
      Get.put(
        AiAssistantController(bvid: bvid, cid: cid),
        tag: tag,
      );
    }

    // 显示底部抽屉
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => AiAssistantPanel(
          bvid: bvid,
          cid: cid,
          heroTag: heroTag,
        ),
      ),
    );
  }

  /// 销毁控制器（在视频页面关闭时调用）
  static void dispose(String heroTag) {
    final tag = 'ai_$heroTag';
    if (Get.isRegistered<AiAssistantController>(tag: tag)) {
      Get.delete<AiAssistantController>(tag: tag);
    }
  }

  @override
  State<AiAssistantPanel> createState() => _AiAssistantPanelState();
}

class _AiAssistantPanelState extends State<AiAssistantPanel> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final AiAssistantController _controller;
  AiService get _aiService => AiService.to;

  @override
  void initState() {
    super.initState();
    final tag = 'ai_${widget.heroTag}';
    _controller = Get.find<AiAssistantController>(tag: tag);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendSelectedPrompt() {
    final prompts = _aiService.prompts;
    if (prompts.isEmpty) return;
    final index = _controller.selectedPromptIndex.value;
    if (index >= 0 && index < prompts.length) {
      _controller.sendPrompt(prompts[index].content);
    }
  }

  void _sendCustomPrompt() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    _controller.sendPrompt(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prompts = _aiService.prompts;

    return Column(
      children: [
        // 拖动条
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // 标题栏
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'AI 视频助手',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Obx(() {
                if (_controller.chatHistory.isNotEmpty) {
                  return TextButton.icon(
                    onPressed: _controller.resetConversation,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('重置'),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 提示词下拉框和发送按钮
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Obx(
                  () => DropdownButtonFormField<int>(
                    value: _controller.selectedPromptIndex.value < prompts.length
                        ? _controller.selectedPromptIndex.value
                        : 0,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                    items: prompts.asMap().entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(
                          entry.value.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _controller.selectedPromptIndex.value = value;
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Obx(
                () => FilledButton.icon(
                  onPressed: _controller.isLoadingAi.value ||
                          _controller.subtitle.value.isEmpty
                      ? null
                      : _sendSelectedPrompt,
                  icon: _controller.isLoadingAi.value
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: const Text('分析'),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 24),

        // 内容区域
        Expanded(
          child: Obx(() {
            // 加载字幕中
            if (_controller.isLoadingSubtitle.value) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('正在加载字幕...'),
                  ],
                ),
              );
            }

            // 错误状态（无字幕或加载失败）
            if (_controller.errorMsg.value.isNotEmpty &&
                _controller.aiResponse.value.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _controller.errorMsg.value,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _controller.retryLoadSubtitle,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // AI 加载中
            if (_controller.isLoadingAi.value) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('AI 正在思考...'),
                  ],
                ),
              );
            }

            // AI 响应 - 使用 Markdown 渲染
            if (_controller.aiResponse.value.isNotEmpty) {
              return SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SelectionArea(
                  child: Html(
                    data: _markdownToHtml(_controller.aiResponse.value),
                    style: {
                      'html': Style(
                        fontSize: FontSize(15),
                        lineHeight: LineHeight.percent(160),
                      ),
                      'body': Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                      ),
                      'p': Style(
                        margin: Margins.only(bottom: 8),
                      ),
                      'h1,h2': Style(
                        fontSize: FontSize(18),
                        fontWeight: FontWeight.bold,
                        margin: Margins.only(top: 12, bottom: 8),
                      ),
                      'h3,h4,h5,h6': Style(
                        fontSize: FontSize(16),
                        fontWeight: FontWeight.bold,
                        margin: Margins.only(top: 8, bottom: 4),
                      ),
                      'li': Style(
                        padding: HtmlPaddings.only(bottom: 4),
                      ),
                      'code': Style(
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
                        fontFamily: 'monospace',
                      ),
                      'pre': Style(
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        padding: HtmlPaddings.all(12),
                        margin: Margins.only(top: 8, bottom: 8),
                      ),
                      'strong': Style(fontWeight: FontWeight.bold),
                      'em': Style(fontStyle: FontStyle.italic),
                    },
                  ),
                ),
              );
            }

            // 空状态 - 提示用户选择并分析
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 48,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '选择提示词后点击「分析」开始',
                      style: TextStyle(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),

        // 底部输入框
        Container(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            8 + MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  decoration: InputDecoration(
                    hintText: '输入问题继续对话...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendCustomPrompt(),
                ),
              ),
              const SizedBox(width: 8),
              Obx(
                () => IconButton.filled(
                  onPressed: _controller.isLoadingAi.value ||
                          _controller.subtitle.value.isEmpty
                      ? null
                      : _sendCustomPrompt,
                  icon: const Icon(Icons.send),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
