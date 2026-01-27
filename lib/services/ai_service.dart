import 'dart:convert';

import 'package:PiliPlus/http/init.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// AI 提示词模型
class AiPrompt {
  final String title;
  final String content;

  AiPrompt({required this.title, required this.content});

  factory AiPrompt.fromJson(Map<String, dynamic> json) => AiPrompt(
        title: json['title'] ?? '',
        content: json['content'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
      };
}

/// AI 视频助手服务
class AiService extends GetxService {
  static AiService get to => Get.find<AiService>();

  // 配置
  String get apiUrl =>
      GStorage.setting.get(SettingBoxKey.aiApiUrl, defaultValue: '') as String;
  set apiUrl(String value) =>
      GStorage.setting.put(SettingBoxKey.aiApiUrl, value);

  String get apiKey =>
      GStorage.setting.get(SettingBoxKey.aiApiKey, defaultValue: '') as String;
  set apiKey(String value) =>
      GStorage.setting.put(SettingBoxKey.aiApiKey, value);

  String get modelName =>
      GStorage.setting.get(SettingBoxKey.aiModelName, defaultValue: '') as String;
  set modelName(String value) =>
      GStorage.setting.put(SettingBoxKey.aiModelName, value);

  /// 获取提示词列表（包含标题和内容）
  List<AiPrompt> get prompts {
    final data = GStorage.setting.get(SettingBoxKey.aiPrompts);
    if (data == null) {
      return _defaultPrompts;
    }
    try {
      final list = jsonDecode(data as String) as List;
      return list.map((e) => AiPrompt.fromJson(e)).toList();
    } catch (_) {
      return _defaultPrompts;
    }
  }

  set prompts(List<AiPrompt> value) {
    final json = jsonEncode(value.map((e) => e.toJson()).toList());
    GStorage.setting.put(SettingBoxKey.aiPrompts, json);
  }

  static final List<AiPrompt> _defaultPrompts = [
    AiPrompt(title: '总结视频', content: '请总结这个视频的主要内容，包括核心观点和关键信息。'),
    AiPrompt(title: '提取要点', content: '请提取这个视频的关键要点，以列表形式展示。'),
    AiPrompt(title: '详细分析', content: '请对这个视频内容进行详细分析，包括主题、论点、论据等。'),
  ];

  /// 获取缓存的模型列表
  List<String> get cachedModels {
    final data = GStorage.setting.get(SettingBoxKey.aiCachedModels);
    if (data == null) return [];
    try {
      return List<String>.from(jsonDecode(data as String));
    } catch (_) {
      return [];
    }
  }

  set cachedModels(List<String> value) {
    GStorage.setting.put(SettingBoxKey.aiCachedModels, jsonEncode(value));
  }

  /// 检查是否已配置
  bool get isConfigured => apiUrl.isNotEmpty && apiKey.isNotEmpty;

  /// 获取可用模型列表
  Future<LoadingState<List<String>>> fetchModels() async {
    if (apiUrl.isEmpty || apiKey.isEmpty) {
      return const Error('请先配置 API 地址和 Key');
    }

    try {
      final url = apiUrl.endsWith('/')
          ? '${apiUrl}v1/models'
          : '$apiUrl/v1/models';

      final response = await Dio().get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List models = data['data'] ?? [];
        final modelIds = models
            .map<String>((m) => m['id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
        // 缓存模型列表
        cachedModels = modelIds;
        return Success(modelIds);
      } else {
        return Error('请求失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('fetchModels error: $e');
      }
      return Error('网络错误: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('fetchModels error: $e');
      }
      return Error('获取模型列表失败: $e');
    }
  }

  /// 与 AI 对话
  Future<LoadingState<String>> chatWithAi({
    required String prompt,
    required String content,
    List<Map<String, String>>? history,
  }) async {
    if (!isConfigured) {
      return const Error('请先配置 AI API');
    }

    if (modelName.isEmpty) {
      return const Error('请先选择模型');
    }

    try {
      final url = apiUrl.endsWith('/')
          ? '${apiUrl}v1/chat/completions'
          : '$apiUrl/v1/chat/completions';

      final messages = <Map<String, String>>[
        {
          'role': 'system',
          'content': '你是一个视频内容分析助手。用户会提供视频字幕内容，请根据用户的要求进行分析。请使用 Markdown 格式回复。',
        },
        if (history != null) ...history,
        {
          'role': 'user',
          'content': '$prompt\n\n以下是视频字幕内容：\n$content',
        },
      ];

      final response = await Dio().post(
        url,
        data: jsonEncode({
          'model': modelName,
          'messages': messages,
          'temperature': 0.7,
        }),
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'];
          final text = message?['content']?.toString() ?? '';
          return Success(text);
        }
        return const Error('AI 返回为空');
      } else {
        return Error('请求失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('chatWithAi error: $e');
      }
      final msg = e.response?.data?['error']?['message'] ?? e.message;
      return Error('网络错误: $msg');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('chatWithAi error: $e');
      }
      return Error('请求失败: $e');
    }
  }

  /// 获取视频字幕纯文本
  Future<LoadingState<String>> getSubtitleText({
    required String bvid,
    required int cid,
  }) async {
    try {
      // 使用 playInfo API 获取字幕信息
      final result = await VideoHttp.playInfo(bvid: bvid, cid: cid);

      if (result case Success(:final response)) {
        final subtitles = response.subtitle?.subtitles;
        if (subtitles == null || subtitles.isEmpty) {
          return const Error(null); // 无字幕
        }

        // 优先选择中文字幕
        final chineseSubtitle = subtitles
            .where((s) => s.lanDoc?.contains('中文') == true)
            .toList();
        final subtitle =
            chineseSubtitle.isNotEmpty ? chineseSubtitle.first : subtitles.first;

        final subtitleUrl = subtitle.subtitleUrl;
        if (subtitleUrl == null || subtitleUrl.isEmpty) {
          return const Error(null);
        }

        // 下载字幕文件
        final url = subtitleUrl.startsWith('http')
            ? subtitleUrl
            : 'https:$subtitleUrl';

        final res = await Request().get(url);
        final body = res.data?['body'] as List?;
        if (body == null || body.isEmpty) {
          return const Error(null);
        }

        // 提取纯文本
        final sb = StringBuffer();
        for (final item in body) {
          final content = item['content']?.toString().trim();
          if (content != null && content.isNotEmpty) {
            sb.writeln(content);
          }
        }

        final text = sb.toString().trim();
        if (text.isEmpty) {
          return const Error(null);
        }

        return Success(text);
      } else {
        return const Error('获取字幕信息失败');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('getSubtitleText error: $e');
      }
      return Error('获取字幕失败: $e');
    }
  }
}
