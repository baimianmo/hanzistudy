# 讯飞离线语音 SDK 集成指南 (iFlytek Offline TTS Integration Guide)

您已选择使用讯飞离线语音功能。由于讯飞 SDK 是闭源且付费的（含免费试用），且 SDK 与您的 AppID 绑定，因此需要您手动下载并放入指定目录。

## 1. 下载 SDK
1. 访问 [讯飞开放平台](https://www.xfyun.cn/) 并注册/登录。
2. 进入控制台，创建一个新应用，记录下 **AppID**。
3. 在应用服务中选择“离线语音合成”，并下载 **Android SDK**。
   - 注意：下载时需选择“离线语音合成”服务，否则 SDK 中不包含离线功能。

## 2. 放置 SDK 文件
下载并解压 SDK 压缩包后，请将文件放入以下目录：

### (1) Jar 包
将 `libs/Msc.jar` 复制到：
`hanzicard_app/android/app/libs/Msc.jar`

### (2) 动态库 (.so)
将 `libs/arm64-v8a/libmsc.so` (以及其他架构如 armeabi-v7a) 复制到：
`hanzicard_app/android/app/src/main/jniLibs/arm64-v8a/libmsc.so`
(如果 `jniLibs` 目录不存在，请手动创建)

### (3) 资源文件 (.jet)
找到 `assets` 目录下的资源文件（通常是 `common.jet` 和发音人文件如 `xiaoyan.jet`），将它们复制到 Flutter 项目的 assets 目录：
`hanzicard_app/assets/iflytek/common.jet`
`hanzicard_app/assets/iflytek/xiaoyan.jet` (文件名可能不同，请在代码中确认)

## 3. 配置 AppID
打开 `hanzicard_app/android/app/src/main/kotlin/com/example/hanzicard_app/MainActivity.kt`，找到以下行并替换为您申请的 AppID：

```kotlin
private val APP_ID = "XXX" // 替换为您的真实 AppID
```

## 4. 运行
完成上述步骤后，重新运行 `flutter run` 或 `flutter build apk`。

**注意**：如果不放入 `Msc.jar`，项目将无法编译通过。
