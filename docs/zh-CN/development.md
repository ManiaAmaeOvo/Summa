# 开发与发布指南

**简体中文** | [English](../development.md)

## 环境

- macOS（当前主要开发环境为 Apple Silicon）
- Flutter stable 与配套 Dart SDK
- Android SDK、platform-tools 和已接受的 SDK License
- JDK 17

```bash
flutter doctor -v
flutter devices
flutter pub get
flutter run
```

## 质量检查

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

测试覆盖金额精度、账户余额、借入/还款、转账、分类归档、批量导入、完整
备份恢复和主要界面生命周期。

## 构建 Android APK

```bash
flutter build apk --release
```

输出位于 `build/app/outputs/flutter-apk/app-release.apk`。

在已有测试版上验证升级时，应使用 Android platform-tools 中的
`adb install -r <apk>` 原位覆盖安装，以保留应用私有数据。不要使用
`flutter install` 验证数据升级；该命令可能先卸载旧版本并清除本机测试数据。

当前 release 构建仍使用调试签名，只适合内部侧载。公开 Release 前应创建并
安全保存独立上传密钥，通过不纳入 Git 的 `key.properties` 配置 release 签名。

升级版本时修改 `pubspec.yaml` 中的 `version: x.y.z+build`，并同步更新
`CHANGELOG.md`。
