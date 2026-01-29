/// HTML 工具函数

/// 去除 HTML 标签，保留纯文本
String stripHtml(String html) {
  // 移除 script 和 style 标签及内容
  html = html.replaceAll(
      RegExp(r'<(script|style)[^>]*>[\s\S]*?</\1>', caseSensitive: false), '');
  // 移除所有 HTML 标签
  html = html.replaceAll(RegExp(r'<[^>]+>'), '');
  // 解码常见 HTML 实体
  html = html
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&#x27;', "'")
      .replaceAll('&mdash;', '—')
      .replaceAll('&ndash;', '–')
      .replaceAll('&hellip;', '…')
      .replaceAll('&copy;', '©')
      .replaceAll('&reg;', '®');
  // 压缩多余空白
  return html.replaceAll(RegExp(r'\s+'), ' ').trim();
}
