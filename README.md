# create_ios

用脚本在本地**初始化一个可立即用 Xcode 打开的完整 iOS App 工程**（SwiftUI、单 Target、含 `project.yml` + XcodeGen 生成 `.xcodeproj`）。

## 依赖

- **macOS**，已安装 **Xcode**（或具备可用的 iOS SDK / 命令行构建环境）
- **[XcodeGen](https://github.com/yonaskolb/XcodeGen)**（通过 Homebrew 安装）：

```bash
brew install xcodegen
```

脚本会调用 `xcodegen generate`，根据同目录下的 `project.yml` 生成标准 Xcode 工程。

## 文件说明

| 文件 | 说明 |
|------|------|
| `create_ios_project.sh` | 创建工程目录、Swift 源码、`project.yml`、资源占位，并执行 `xcodegen generate` |

## 用法

在终端中执行（建议先赋予执行权限，若尚未执行过）：

```bash
chmod +x create_ios_project.sh
```

### 基本

在当前目录下创建子目录 `项目名/`，并在其中生成 `项目名.xcodeproj` 及源码：

```bash
./create_ios_project.sh MyApp
```

### 指定 Bundle ID

```bash
./create_ios_project.sh MyApp com.yourcompany.myapp
```

未指定时默认为 `com.example.<项目名>`。

### 指定输出父目录

在 `~/Projects` 下创建 `~/Projects/MyApp/`：

```bash
./create_ios_project.sh MyApp com.yourcompany.myapp ~/Projects
```

### 帮助

```bash
./create_ios_project.sh --help
```

（无参数或 `--help` / `-h` 会打印用法并退出。）

## 生成后

```bash
open MyApp/MyApp.xcodeproj
```

将 `MyApp` 换成你的项目名即可。

## 工程约定

- **界面：** SwiftUI（`@main` App + `ContentView`）
- **最低系统：** iOS 15.0（可在生成后的 `project.yml` 中修改 `deploymentTarget`，再执行 `xcodegen generate`）
- **Info.plist：** 使用 Xcode 推荐的自动生成项（`GENERATE_INFOPLIST_FILE` 等）
- **AppIcon：** 脚本仅生成空占位，**上架或部分真机校验前**请在 Xcode 的 Assets 中补全图标

## 常见问题

- **提示「未找到 xcodegen」：** 先执行 `brew install xcodegen`，确认 `which xcodegen` 有路径。
- **提示「已存在路径」：** 同名目录已存在，请换项目名或删除/移动旧目录后再运行。

## 许可

脚本可按需自由修改使用；XcodeGen 遵循其自身开源协议。
