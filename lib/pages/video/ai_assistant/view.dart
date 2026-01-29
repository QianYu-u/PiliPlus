import 'package:PiliPlus/pages/video/ai_assistant/controller.dart';
import 'package:PiliPlus/services/ai_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:markdown/markdown.dart' as m;
import 'package:markdown_widget/markdown_widget.dart';

/// LaTeX 语法解析器
class LatexSyntax extends m.InlineSyntax {
  LatexSyntax() : super(r'(\$\$[\s\S]+?\$\$)|(\$[^\$\n]+?\$)');

  @override
  bool onMatch(m.InlineParser parser, Match match) {
    final input = match.input;
    final matchValue = input.substring(match.start, match.end);
    String content = '';
    bool isInline = true;
    const blockSyntax = r'$$';
    const inlineSyntax = r'$';
    
    if (matchValue.startsWith(blockSyntax) &&
        matchValue.endsWith(blockSyntax) &&
        matchValue.length > 4) {
      content = matchValue.substring(2, matchValue.length - 2);
      isInline = false;
    } else if (matchValue.startsWith(inlineSyntax) &&
        matchValue.endsWith(inlineSyntax) &&
        matchValue.length > 2) {
      content = matchValue.substring(1, matchValue.length - 1);
    }
    
    m.Element el = m.Element.text('latex', matchValue);
    el.attributes['content'] = content;
    el.attributes['isInline'] = '$isInline';
    parser.addNode(el);
    return true;
  }
}

/// LaTeX 节点生成器
SpanNodeGeneratorWithTag latexGenerator(bool isDark) => SpanNodeGeneratorWithTag(
  tag: 'latex',
  generator: (e, config, visitor) => LatexNode(
    e.attributes,
    e.textContent,
    config,
    isDark,
  ),
);

/// LaTeX 渲染节点
class LatexNode extends SpanNode {
  final Map<String, String> attributes;
  final String textContent;
  final MarkdownConfig config;
  final bool isDark;

  LatexNode(this.attributes, this.textContent, this.config, this.isDark);

  @override
  InlineSpan build() {
    final content = attributes['content'] ?? '';
    final isInline = attributes['isInline'] == 'true';
    final style = parentStyle ?? config.p.textStyle;
    
    if (content.isEmpty) {
      return TextSpan(style: style, text: textContent);
    }
    
    final latex = Math.tex(
      content,
      mathStyle: MathStyle.text,
      textStyle: style.copyWith(
        color: isDark ? Colors.white : Colors.black,
      ),
      textScaleFactor: 1,
      onErrorFallback: (error) {
        return Text(
          textContent,
          style: style.copyWith(color: Colors.red),
        );
      },
    );
    
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: isInline
          ? latex
          : Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: latex),
            ),
    );
  }
}

/// AI 视频助手面板
class AiAssistantPanel extends StatefulWidget {
  const AiAssistantPanel({
    super.key,
    this.bvid,
    this.cid,
    required this.heroTag,
    this.sceneType = AiSceneType.video,
  });

  final String? bvid;
  final int? cid;
  final String heroTag;
  final AiSceneType sceneType;

  /// 显示 AI 助手面板（视频模式）
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
        AiAssistantController(
          bvid: bvid,
          cid: cid,
          sceneType: AiSceneType.video,
        ),
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

  /// 显示 AI 助手面板（专栏模式）
  static void showForOpus({
    required BuildContext context,
    required String heroTag,
    required String title,
    required String content,
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

    // 截断超长内容
    String processedContent = content;
    if (content.length > 5000) {
      processedContent = '${content.substring(0, 5000)}...（内容已截断）';
    }

    // 获取或创建控制器
    final tag = 'ai_opus_$heroTag';
    if (!Get.isRegistered<AiAssistantController>(tag: tag)) {
      Get.put(
        AiAssistantController(
          sceneType: AiSceneType.opus,
          directContent: '文章标题：$title\n\n$processedContent',
        ),
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
          heroTag: heroTag,
          sceneType: AiSceneType.opus,
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
    final opusTag = 'ai_opus_$heroTag';
    if (Get.isRegistered<AiAssistantController>(tag: opusTag)) {
      Get.delete<AiAssistantController>(tag: opusTag);
    }
  }


  @override
  State<AiAssistantPanel> createState() => _AiAssistantPanelState();
}

class _AiAssistantPanelState extends State<AiAssistantPanel> {
  final TextEditingController _inputController = TextEditingController();

  late final AiAssistantController _controller;
  AiService get _aiService => AiService.to;

  @override
  void initState() {
    super.initState();
    final tag = widget.sceneType == AiSceneType.opus
        ? 'ai_opus_${widget.heroTag}'
        : 'ai_${widget.heroTag}';
    _controller = Get.find<AiAssistantController>(tag: tag);
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _sendSelectedPrompt() {
    final prompts = _aiService.getPrompts(widget.sceneType);
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

  void _copyToClipboard() {
    final text = _controller.aiResponse.value;
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    SmartDialog.showToast('已复制到剪贴板');
  }

  /// 构建 Markdown 配置
  MarkdownConfig _buildMarkdownConfig(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    
    return MarkdownConfig(
      configs: [
        // 段落样式
        PConfig(
          textStyle: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: textColor,
          ),
        ),
        // 标题样式
        H1Config(
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
            height: 1.5,
          ),
        ),
        H2Config(
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
            height: 1.5,
          ),
        ),
        H3Config(
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
            height: 1.4,
          ),
        ),
        // 引用样式
        BlockquoteConfig(
          sideColor: theme.colorScheme.primary,
          textColor: textColor.withValues(alpha: 0.8),
        ),
        // 代码块样式
        PreConfig(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: textColor,
          ),
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
        // 行内代码样式
        CodeConfig(
          style: TextStyle(
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            fontFamily: 'monospace',
            fontSize: 13,
            color: theme.colorScheme.primary,
          ),
        ),
        // 链接样式
        LinkConfig(
          style: TextStyle(
            color: theme.colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
        ),
        // 列表样式
        ListConfig(
          marker: (isOrdered, depth, index) {
            if (isOrdered) {
              return Text(
                '${index + 1}.',
                style: TextStyle(color: textColor),
              );
            }
            return Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 8, right: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            );
          },
        ),
        // 分割线样式
        HrConfig(
          color: theme.colorScheme.outlineVariant,
          height: 1,
        ),
        // 表格样式
        TableConfig(
          headerRowDecoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          bodyRowDecoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant,
                width: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建 Markdown Generator
  MarkdownGenerator _buildMarkdownGenerator(bool isDark) {
    return MarkdownGenerator(
      generators: [
        latexGenerator(isDark),
      ],
      inlineSyntaxList: [
        LatexSyntax(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prompts = _aiService.getPrompts(widget.sceneType);
    final isDark = theme.brightness == Brightness.dark;

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

            // AI 响应 - 使用 markdown_widget 渲染
            if (_controller.aiResponse.value.isNotEmpty) {
              return Stack(
                children: [
                  MarkdownWidget(
                    data: _controller.aiResponse.value,
                    shrinkWrap: false,
                    selectable: true,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 56),
                    config: _buildMarkdownConfig(context),
                    markdownGenerator: _buildMarkdownGenerator(isDark),
                  ),
                  // 复制按钮
                  Positioned(
                    right: 16,
                    bottom: 8,
                    child: Material(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                      elevation: 2,
                      child: InkWell(
                        onTap: _copyToClipboard,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            Icons.copy,
                            size: 20,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
