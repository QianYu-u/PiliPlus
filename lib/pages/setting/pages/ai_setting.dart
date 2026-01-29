import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/services/ai_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

/// AI 视频助手设置页面
class AiSettingPage extends StatefulWidget {
  const AiSettingPage({super.key});

  @override
  State<AiSettingPage> createState() => _AiSettingPageState();
}

class _AiSettingPageState extends State<AiSettingPage> {
  late final TextEditingController _urlController;
  late final TextEditingController _keyController;

  final RxList<String> _models = <String>[].obs;
  final RxString _selectedModel = ''.obs;
  final RxBool _isLoadingModels = false.obs;
  
  // 视频和专栏预设提示词分开管理
  final RxList<AiPrompt> _videoPrompts = <AiPrompt>[].obs;
  final RxList<AiPrompt> _opusPrompts = <AiPrompt>[].obs;
  final Rx<AiSceneType> _selectedPromptsType = AiSceneType.video.obs;

  AiService get _aiService => AiService.to;
  
  // 获取当前选中类型的提示词列表
  RxList<AiPrompt> get _currentPrompts => 
      _selectedPromptsType.value == AiSceneType.video ? _videoPrompts : _opusPrompts;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: _aiService.apiUrl);
    _keyController = TextEditingController(text: _aiService.apiKey);
    _selectedModel.value = _aiService.modelName;
    _videoPrompts.value = List.from(_aiService.videoPrompts);
    _opusPrompts.value = List.from(_aiService.opusPrompts);
    // 加载缓存的模型列表
    _models.value = _aiService.cachedModels;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _fetchModels() async {
    // 先保存当前输入的配置
    _aiService.apiUrl = _urlController.text.trim();
    _aiService.apiKey = _keyController.text.trim();

    _isLoadingModels.value = true;
    final result = await _aiService.fetchModels();
    _isLoadingModels.value = false;

    if (result case Success(:final response)) {
      _models.value = response;
      if (response.isNotEmpty && !response.contains(_selectedModel.value)) {
        _selectedModel.value = response.first;
        _aiService.modelName = response.first;
      }
      SmartDialog.showToast('获取到 ${response.length} 个模型');
    } else if (result case Error(:final errMsg)) {
      SmartDialog.showToast(errMsg ?? '获取模型失败');
    }
  }

  void _saveConfig() {
    _aiService.apiUrl = _urlController.text.trim();
    _aiService.apiKey = _keyController.text.trim();
    _aiService.modelName = _selectedModel.value;
    _aiService.videoPrompts = _videoPrompts.toList();
    _aiService.opusPrompts = _opusPrompts.toList();
    SmartDialog.showToast('保存成功');
  }

  void _addPrompt() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加提示词'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                hintText: '例如：总结视频',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: '提示词内容',
                hintText: '例如：请总结这个视频的主要内容',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              final content = contentController.text.trim();
              if (title.isEmpty || content.isEmpty) {
                SmartDialog.showToast('标题和内容不能为空');
                return;
              }
              _currentPrompts.add(AiPrompt(title: title, content: content));
              _saveCurrentPrompts();
              Navigator.pop(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _removePrompt(int index) {
    _currentPrompts.removeAt(index);
    _saveCurrentPrompts();
  }

  /// 保存当前选中类型的提示词到存储
  void _saveCurrentPrompts() {
    _aiService.setPrompts(_selectedPromptsType.value, _currentPrompts.toList());
  }

  void _editPrompt(int index) {
    final prompt = _currentPrompts[index];
    final titleController = TextEditingController(text: prompt.title);
    final contentController = TextEditingController(text: prompt.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑提示词'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: '提示词内容',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              final content = contentController.text.trim();
              if (title.isEmpty || content.isEmpty) {
                SmartDialog.showToast('标题和内容不能为空');
                return;
              }
              _currentPrompts[index] = AiPrompt(title: title, content: content);
              _saveCurrentPrompts();
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 视频助手'),
        actions: [
          IconButton(
            onPressed: _saveConfig,
            icon: const Icon(Icons.save),
            tooltip: '保存',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // API 配置区域
          _buildSectionTitle('API 配置'),
          const SizedBox(height: 12),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: '接口地址',
              hintText: 'https://api.openai.com',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _keyController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'API Key',
              hintText: 'sk-...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.key),
            ),
          ),
          const SizedBox(height: 16),

          // 模型选择
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => DropdownButtonFormField<String>(
                    value: _models.contains(_selectedModel.value)
                        ? _selectedModel.value
                        : null,
                    decoration: const InputDecoration(
                      labelText: '模型',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.smart_toy),
                    ),
                    items: _models
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _selectedModel.value = value;
                        _aiService.modelName = value;
                      }
                    },
                    hint: const Text('请先获取模型列表'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Obx(
                () => IconButton.filled(
                  onPressed: _isLoadingModels.value ? null : _fetchModels,
                  icon: _isLoadingModels.value
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  tooltip: '获取模型列表',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 预设提示词区域
          Row(
            children: [
              _buildSectionTitle('预设提示词'),
              const Spacer(),
              IconButton.filled(
                onPressed: _addPrompt,
                icon: const Icon(Icons.add),
                tooltip: '添加提示词',
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 视频/专栏切换
          Obx(
            () => SegmentedButton<AiSceneType>(
              segments: const [
                ButtonSegment(
                  value: AiSceneType.video,
                  label: Text('视频预设'),
                  icon: Icon(Icons.video_library_outlined),
                ),
                ButtonSegment(
                  value: AiSceneType.opus,
                  label: Text('专栏预设'),
                  icon: Icon(Icons.article_outlined),
                ),
              ],
              selected: {_selectedPromptsType.value},
              onSelectionChanged: (Set<AiSceneType> selection) {
                _selectedPromptsType.value = selection.first;
              },
            ),
          ),
          const SizedBox(height: 12),
          
          Obx(
            () => ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _currentPrompts.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
                final item = _currentPrompts.removeAt(oldIndex);
                _currentPrompts.insert(newIndex, item);
                _saveCurrentPrompts();
              },
              itemBuilder: (context, index) {
                final prompt = _currentPrompts[index];
                return Card(
                  key: ValueKey('${prompt.title}_$index'),
                  child: ListTile(
                    title: Text(
                      prompt.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      prompt.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.outline,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _editPrompt(index),
                          icon: const Icon(Icons.edit),
                          iconSize: 20,
                        ),
                        IconButton(
                          onPressed: () => _removePrompt(index),
                          icon: const Icon(Icons.delete_outline),
                          iconSize: 20,
                        ),
                        const Icon(Icons.drag_handle),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // 说明
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '使用说明',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 支持 OpenAI 兼容的 API 接口\n'
                    '• 在视频详情页点击 AI 按钮使用\n'
                    '• 会自动提取视频字幕作为上下文\n'
                    '• 支持 Markdown 格式和 LaTeX 公式',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
