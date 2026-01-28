<div align="center">
    <img width="200" height="200" src="assets/images/logo/logo.png">
</div>



<div align="center">
    <h1>PiliPlus</h1>
    <p>使用Flutter开发的BiliBili第三方客户端</p>
    
<img src="assets/screenshots/510shots_so.png" width="32%" alt="home" />
<img src="assets/screenshots/174shots_so.png" width="32%" alt="home" />
<img src="assets/screenshots/850shots_so.png" width="32%" alt="home" />
<br/>
<img src="assets/screenshots/main_screen.png" width="96%" alt="home" />
<br/>
</div>

<br/>

## 📱 适配平台
- [x] Android / iOS / Pad
- [x] Windows / Linux

[![Packaging status](https://repology.org/badge/vertical-allrepos/piliplus.svg)](https://repology.org/project/piliplus/versions)

---

## 🤖 个人 Fork 新增功能：AI 视频助手
> 本 Fork 基于上游 [bggRGjQaUbCoE/PiliPlus](https://github.com/bggRGjQaUbCoE/PiliPlus) 修改。

使用自定义 OpenAI 兼容 API 对视频字幕进行 AI 分析：
- **智能分析**：自动提取视频字幕作为上下文.
- **自定义配置**：支持 API 地址、Key、模型选择及预设提示词（Prompt）模板.
- **会话保持**：视频页内保持对话状态，支持模型列表缓存.
- **Markdown渲染**：标题,引用,分割等回复渲染.
- **LaTeX公式**：适配LaTeX渲染公式.

---

## ✨ 功能特性 (feat)

### 📺 播放体验
- **核心播放**：支持 DLNA 投屏、离线缓存、音频模式、互动视频、播放全部/记忆播放。
- **画质增强**：支持超分辨率、硬件加速、画质/音质/解码格式自定义选择。
- **高级交互**：
  - **SponsorBlock**：自动跳过视频内广告/无用片段。
  - **高阶控制**：跳过片头片尾、高能进度条、缩略图预览、Live Photo。
  - **音频适配**：安卓端 `loudnorm` 音量平衡适配 by [@My-Responsitories](https://github.com/My-Responsitories)。
- **弹幕字幕**：高级弹幕、合并弹幕、彩色弹幕；支持弹幕悬停交互（点赞/复制/举报）及尺寸调节。

### 💬 社交与动态
- **动态全功能**：发布/编辑/转发动态（支持富文本、@用户、投票、话题、带图评论）。
- **评论系统**：楼中楼对话模式（支持排序/定位）、评论点踩、保存评论图片。
- **私信交互**：完整私信功能（发图/撤回/置顶）、分享视频/专栏/直播至私信。
- **直播增强**：直播弹幕（含表情）、SuperChat、直播分区浏览。

### 📂 资源管理
- **收藏与稍后**：支持收藏夹/稍后再看的**多选删除、排序、复制、移动**。
- **内容发现**：推荐/最热视频、热门直播、番剧列表、搜索筛选（支持时长/排序）。
- **订阅管理**：关注分组管理、移除粉丝、合集订阅、追番状态管理。
- **安全与隐私**：无痕模式、游客模式、屏蔽带货动态/评论、发评反诈提醒。

### ⚙️ 系统与设置
- **登录支持**：支持短信、极验、Cookie、多账号切换 by [@My-Responsitories](https://github.com/My-Responsitories)。
- **备份同步**：支持 **WebDAV** 备份与恢复设置。
- **个性化**：主题模式（亮/暗/跟随系统）、震动反馈、自定义图片质量、修改个人资料。

---

## 🛠 维护与优化

### 优化 (opt)
- [x] 界面精修：专栏、私信、收藏面板、回复界面、视频封面优化。
- [x] 交互体验：PIP 画中画、系统通知适配、亮度调节、防止全屏遮挡。

### 修复 (fix)
- [x] 番剧分集交互（点赞/投币/收藏）修复。
- [x] 修复已知 Bugs。

### 重构 (refactor)
- [ ] gRPC 协议支持 [WIP]
- [x] 用户界面重构

---

## 📥 下载与安装
可以通过右侧 **Releases** 下载对应平台的安装包，或拉取代码自行编译。

## ⚖️ 声明
本项目仅供学习和测试，请于下载后 24 小时内删除。
在此致敬原作者：[guozhigq/pilipala](https://github.com/guozhigq/pilipala) 及上游作者：[orz12/PiliPalaX](https://github.com/orz12/PiliPalaX) / [bggRGjQaUbCoE/PiliPlus](https://github.com/bggRGjQaUbCoE/PiliPlus?tab=readme-ov-file)
