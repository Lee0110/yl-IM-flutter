<div align="center">

# yl-IM-flutter

一个用 Flutter 构建的轻量级即时通讯（IM）演示客户端，通过 WebSocket 与服务端双向通信，支持断线重连、系统消息提示与基础私聊。

[配套后端：yl-IM](https://github.com/Lee0110/yl-IM) · 开源协议：MIT

</div>

## 目录

- 项目简介
- 功能特性
- 快速开始
- 配置说明（开发/生产）
- 常见问题与排错
- 目录结构
- 技术栈
- 规划与待办
- 许可证

## 项目简介

本项目是一个跨平台（Android/iOS/Web/Windows/macOS/Linux）的聊天应用演示客户端，基于 Flutter 实现。前端通过 `web_socket_channel` 与后端保持长连接，支持用户 A 与用户 B 之间的点对点消息收发，并在 UI 中展示连接状态与系统消息。

- 前端仓库（当前）：本项目
- 后端仓库（配套）：https://github.com/Lee0110/yl-IM

## 功能特性

- WebSocket 实时通信：消息双向传输，传输字段包含 senderId / receiverId / content / type
- 断线重连：指数退避（最大 10 次），连接状态指示（wifi/wifi_off 图标）
- 系统消息识别：识别后端空闲超时等系统消息，并在必要时停止自动重连并提示
- 简洁 UI：消息气泡、输入框、发送按钮，支持“我/对方”身份展示
- 多环境支持：`dev`/`prod` 配置，顶部条显示当前环境
- 可自定义服务地址：登录页可输入后端 WebSocket 地址，便于本地或内网调试

## 快速开始

### 1) 准备环境

- Flutter（建议使用稳定分支的较新版本）
- Dart SDK ≥ 3.8（项目 `pubspec.yaml` 要求）
- 移动端/桌面端各平台的基础构建环境

可参考官方文档完成安装与环境校验：
https://docs.flutter.dev/get-started/install

### 2) 启动后端（必需）

本前端依赖配套后端服务（默认使用 WebSocket 路径 `/ws`）。请按照后端仓库文档启动服务：

- yl-IM 后端：https://github.com/Lee0110/yl-IM
- 默认本地地址：`ws://localhost:10002/ws`

提示：
- Android 模拟器访问宿主机请使用 `10.0.2.2:10002/ws`
- iOS 模拟器通常可直接使用 `localhost:10002/ws`
- 同一局域网真机调试可使用电脑局域网 IP，如 `192.168.x.x:10002/ws`

### 3) 拉取依赖并运行

在项目根目录执行：

```bash
flutter pub get
flutter run
```

运行后会先进入“登录页”，请按以下规则填写：

- 用户ID：仅数字，例如 `1001`
- 接收者ID：仅数字，例如 `1002`
- WebSocket地址：仅填写“主机:端口/路径”，不要包含协议前缀
	- 正确示例：`localhost:10002/ws`、`10.0.2.2:10002/ws`、`192.168.1.10:10002/ws`
	- 错误示例：`ws://localhost:10002/ws`（应用会自动拼接 `ws://` 前缀，重复会导致连接失败）

进入聊天页后即可开始互发消息。

## 配置说明（开发/生产）

代码位置：`lib/config/app_config.dart`

- 环境枚举：`Environment.dev` 与 `Environment.prod`
- 默认环境：`dev`
- 默认 WebSocket：
	- dev：`ws://localhost:10002/ws`
	- prod：`wss://chat.yourdomain.com/ws`（请按需替换）

注意：
- 登录页输入了自定义地址后，首次连接会优先使用该地址。
- 发送失败时触发的“临时重连”可能会回退到 `AppConfig` 中的默认地址，请保持二者一致，或重新进入会话。

## 常见问题与排错

- 无法连接/一直重连
	- 确认后端已启动且可通过 `ws://<host>:<port>/ws` 访问
	- 确认在登录页填写的地址无 `ws://` 前缀（应仅填写 `host:port/path`）
	- Android 模拟器请用 `10.0.2.2`
- 收到“连接因长时间无响应被服务器关闭”
	- 这是后端的系统消息，客户端会停止自动重连。请退出会话并重新进入。
- Web 端运行跨域问题
	- 如通过 `flutter run -d chrome` 运行，需要后端允许对应源或使用反向代理。

## 目录结构（节选）

```
lib/
	main.dart                    # 入口
	config/app_config.dart       # 环境与后端地址配置
	models/message.dart          # 消息实体
	services/websocket_service.dart # WebSocket 连接、重连、发送
	screens/login_page.dart      # 登录/会话参数输入页
	screens/chat_page.dart       # 聊天页，消息列表与状态提示
	widgets/
		message_bubble.dart        # 消息气泡
		message_input.dart         # 输入与发送按钮
	utils/validators.dart        # 简单校验工具
```

## 技术栈

- Flutter（Material3）
- web_socket_channel
- http（预留/可选）

## 许可证

本项目采用 MIT License 开源协议，详情见 [LICENSE](./LICENSE)。

—— 如果本项目对你有帮助，欢迎 Star；也欢迎提交 Issue 与 PR 一起完善它。

