# create_ios

用脚本在本地**初始化一个可立即用 Xcode 打开的完整 iOS App 工程**（单 Target、含 `project.yml`，由 XcodeGen 生成 `.xcodeproj`）。可通过参数选择 **编程语言**（Swift / Objective-C）、**界面**（SwiftUI / UIKit）以及 **最低 iOS 版本**。

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
| `create_ios_project.sh` | 创建工程目录、源码模板、`project.yml`、资源占位，并执行 `xcodegen generate` |
| `install.sh` | 将上述脚本安装为本地命令 **`iospc`**（默认安装到 `~/.local/bin`） |

## 安装为命令 `iospc`

安装完成后，可在任意目录使用命令 **`iospc`** 创建工程，效果与直接运行仓库里的 `./create_ios_project.sh` 相同。

**安装结果：** 在指定目录（默认 `~/.local/bin`）生成可执行文件 **`iospc`**（内容来自 `create_ios_project.sh`）。

### 方式 A：curl 一键安装（推荐，无需 clone）

**前置条件：** 本机已安装 **`curl`**，且能访问 GitHub（下载 `install.sh` 与 `create_ios_project.sh`）。

1. 在终端执行（可复制整行）：

   ```bash
   curl -fsSL https://raw.githubusercontent.com/hlyProjectHub/CreateIOS/main/install.sh | bash
   ```

2. 阅读终端输出：若提示安装路径不在 `PATH` 中，继续第 3 步；否则跳到第 4 步。

3. **配置 PATH（默认安装目录为 `~/.local/bin` 时）：**  
   - 使用 **zsh**（macOS 默认）：用编辑器打开 `~/.zshrc`，在文件末尾追加一行：
     ```bash
     export PATH="$HOME/.local/bin:$PATH"
     ```
     保存后执行 `source ~/.zshrc`，或重新打开终端窗口。  
   - 使用 **bash**：可在 `~/.bash_profile` 或 `~/.profile` 中追加同样一行，然后 `source` 对应文件或重开终端。

4. **验证是否可用：**

   ```bash
   command -v iospc
   iospc --help
   ```

**自定义安装目录（curl）：** 把环境变量写在 `curl` 与 `bash` 之间，传给管道后的 shell：

```bash
curl -fsSL https://raw.githubusercontent.com/hlyProjectHub/CreateIOS/main/install.sh | INSTALL_PREFIX=~/bin bash
```

**使用 fork 或其它分支上的 `create_ios_project.sh`：** 设置 `IOSPC_RAW_BASE` 为「raw 根地址」（**不要**末尾斜杠），该 URL 所在目录下需有文件 `create_ios_project.sh`：

```bash
curl -fsSL https://raw.githubusercontent.com/hlyProjectHub/CreateIOS/main/install.sh | IOSPC_RAW_BASE=https://raw.githubusercontent.com/你的用户/你的仓库/你的分支 bash
```

若你 fork 后改动了 `install.sh`，也可把上面命令里 **第一个 URL** 换成你 fork 的 `install.sh` 的 raw 地址。

### 方式 B：在已 clone 的仓库中安装

**前置条件：** 已 `git clone` 本仓库（或解压得到完整目录），且 **`install.sh` 与 `create_ios_project.sh` 在同一目录**。此方式**不经过网络**读取 `create_ios_project.sh`，无需 `curl`。

1. 进入仓库根目录。
2. 赋予执行权限并安装到默认目录 `~/.local/bin`：

   ```bash
   chmod +x install.sh
   ./install.sh
   ```

3. 若终端提示安装目录不在 `PATH` 中，按 **方式 A 第 3 步** 配置 `PATH`。
4. 执行 `iospc --help` 验证。

**指定安装目录（本地）：**

```bash
./install.sh --prefix ~/bin
./install.sh -p "$HOME/bin"
```

**安装到系统目录（需写入权限，常配合 sudo）：**

```bash
sudo env INSTALL_PREFIX=/usr/local/bin ./install.sh
```

**查看安装脚本自身帮助：**

```bash
./install.sh --help
```

### 安装相关环境变量

| 变量 | 说明 |
|------|------|
| `INSTALL_PREFIX` | 安装目录，默认 `$HOME/.local/bin`；最终命令路径为 `<INSTALL_PREFIX>/iospc`。 |
| `IOSPC_RAW_BASE` | 仅 **curl 管道安装** 且当前目录**没有**同目录的 `create_ios_project.sh` 时生效：从此 URL 对应目录下载 `create_ios_project.sh`。默认 `https://raw.githubusercontent.com/hlyProjectHub/CreateIOS/main`（无末尾 `/`）。 |

### 升级与卸载

- **升级：** 再次执行与首次相同的安装命令即可覆盖 `iospc`（curl 一条命令，或在本仓库根目录再执行 `./install.sh`）。
- **卸载：** 删除安装目录下的 `iospc`，例如默认路径：
  ```bash
  rm -f "$HOME/.local/bin/iospc"
  ```
  若曾使用 `--prefix` / `INSTALL_PREFIX`，请删除对应目录中的 `iospc`。

## 用法

已按上文安装 **`iospc`** 后，可直接使用 `iospc`。若未安装，可在仓库根目录执行（需先 `chmod +x create_ios_project.sh`）：

```bash
./create_ios_project.sh [选项] <项目名> [Bundle ID] [输出目录]
```

### 命令格式

```text
iospc [选项] <项目名> [Bundle ID] [输出目录]
```

（未安装 `iospc` 时，将 `iospc` 换成 `./create_ios_project.sh` 且需在脚本所在目录或写出脚本全路径。）

**选项**（均可与位置参数混写，脚本会先解析选项再读取项目名等）：

| 选项 | 说明 |
|------|------|
| `-l`, `--language` | 编程语言：`swift` 或 `objc`（默认 `swift`） |
| `-u`, `--ui` | 界面：`swiftui` 或 `uikit`（默认 `swiftui`；Objective-C 时仅支持 `uikit`） |
| `-m`, `--ios` | 最低 iOS 版本（写入 `deploymentTarget.iOS`），如 `15.0`、`16`，默认 `15.0` |
| `--deployment-target` | 与 `-m` / `--ios` 同义 |
| `-h, --help` | 打印用法并退出 |

**约定：**

- **SwiftUI 仅支持 Swift。** 若使用 `--language objc` 且 `--ui swiftui`，脚本会报错退出。
- **Objective-C** 工程仅生成 **UIKit** 模板（`main.m`、`AppDelegate`、`ViewController`）。

### 基本

在当前目录下创建子目录 `项目名/`，并在其中生成 `项目名.xcodeproj` 及源码（默认：**Swift + SwiftUI**，最低 **iOS 15.0**）：

```bash
iospc MyApp
```

### 指定 Bundle ID

```bash
iospc MyApp com.yourcompany.myapp
```

未指定时默认为 `com.example.<项目名>`。

### 指定输出父目录

在 `~/Projects` 下创建 `~/Projects/MyApp/`：

```bash
iospc MyApp com.yourcompany.myapp ~/Projects
```

### 指定界面与最低系统（Swift）

使用 **UIKit**、最低 **iOS 14.0**：

```bash
iospc --ui uikit --ios 14.0 MyApp
```

使用 **SwiftUI**、最低 **iOS 16.0**：

```bash
iospc -u swiftui -m 16.0 MyApp com.example.myapp
```

### 指定 Objective-C + UIKit

```bash
iospc --language objc --ui uikit --ios 13.0 MyApp com.yourcompany.myapp ~/Projects
```

### 帮助

```bash
iospc --help
```

无必填参数（缺少项目名）或 `--help` / `-h` 会打印用法并退出。

## 生成后

```bash
open MyApp/MyApp.xcodeproj
```

将 `MyApp` 换成你的项目名；若指定了输出目录，路径为 `<输出目录>/<项目名>/<项目名>.xcodeproj`。

## 工程约定

- **语言与界面：** 由命令行选项决定。Swift + SwiftUI 时为 `@main` App 与 `ContentView`；Swift + UIKit 时为 `AppDelegate` + `ViewController`（无 Storyboard）；Objective-C 为经典 UIKit 入口与视图控制器。
- **最低系统：** 默认 iOS 15.0；可通过 `-m` / `--ios` 指定。生成后仍可在 `project.yml` 中修改 `deploymentTarget`，再执行 `xcodegen generate`。
- **Info.plist：** 使用 Xcode 推荐的自动生成项（`GENERATE_INFOPLIST_FILE` 等）；SwiftUI 会启用 Scene Manifest 相关项，纯 UIKit AppDelegate 模板会关闭 Scene Manifest 生成。
- **AppIcon：** 脚本仅生成空占位，**上架或部分真机校验前**请在 Xcode 的 Assets 中补全图标。

## 常见问题

**安装**

- **`command -v iospc` 无输出：** 未配置 `PATH` 或未安装成功；按「安装为命令 iospc」中 **配置 PATH** 步骤检查 `INSTALL_PREFIX` 目录（默认 `~/.local/bin`）。
- **curl 安装报错或 404：** 确认网络与 GitHub 可访问；仓库需已推送对应分支。使用 fork 时检查 `IOSPC_RAW_BASE` 是否与 raw 页面 URL 一致（区分大小写）。
- **Permission denied：** 对目标目录无写权限时换一个目录，例如 `INSTALL_PREFIX=~/bin`，或对该目录使用合适的权限 / `sudo`（仅本地 `./install.sh` 时适用）。

**创建工程**

- **提示「未找到 xcodegen」：** 先执行 `brew install xcodegen`，确认 `which xcodegen` 有路径。
- **提示「已存在路径」：** 同名目录已存在，请换项目名或删除/移动旧目录后再运行。
- **提示 SwiftUI 与 Objective-C 冲突：** 请改用 `--language swift`，或改用 `--ui uikit`。

## 许可

脚本可按需自由修改使用；XcodeGen 遵循其自身开源协议。
