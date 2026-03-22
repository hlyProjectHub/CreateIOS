#!/usr/bin/env bash
#
# 初始化完整 iOS App 工程（单 Target，XcodeGen 生成 .xcodeproj）。
# 依赖: Xcode 命令行工具 + Homebrew 安装的 xcodegen
#   brew install xcodegen
# 生成后（可选，便于 Cursor/VS Code 跳转）: brew install xcode-build-server
# 跳过 IDE 准备: IOSPC_SKIP_IDE_SETUP=1 ./create_ios_project.sh ...
#
# 用法:
#   ./create_ios_project.sh MyApp
#   ./create_ios_project.sh MyApp --language swift --ui swiftui --ios 16.0
#   ./create_ios_project.sh MyApp com.example.myapp --ui uikit --ios 15.0 ~/Projects
#

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

LANGUAGE="swift"
UI_FRAMEWORK="swiftui"
IOS_MIN="15.0"

usage() {
  cat <<EOF
用法: $SCRIPT_NAME [选项] <项目名> [Bundle ID] [输出目录]

选项:
  -l, --language <swift|objc>   编程语言（默认: swift）
  -u, --ui <swiftui|uikit>      界面框架（默认: swiftui；objc 时仅支持 uikit）
  -m, --ios <版本>              最低 iOS 版本，如 15.0、16（默认: 15.0）
  -h, --help                    显示本说明

说明:
  SwiftUI 仅支持 Swift。Objective-C 工程仅生成 UIKit 模板。

示例:
  $SCRIPT_NAME HelloApp
  $SCRIPT_NAME HelloApp --ui uikit --ios 14.0
  $SCRIPT_NAME HelloApp com.acme.hello --language objc --ios 13.0

需先安装: brew install xcodegen
可选（Cursor/VS Code 跳转）: brew install xcode-build-server
跳过自动生成 buildServer / 首次构建: IOSPC_SKIP_IDE_SETUP=1 $SCRIPT_NAME ...
EOF
  exit 1
}

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      ;;
    -l|--language)
      [[ -n "${2:-}" ]] || { echo "错误: $1 需要参数 swift 或 objc" >&2; exit 1; }
      LANGUAGE="$(echo "$2" | tr '[:upper:]' '[:lower:]')"
      shift 2
      ;;
    -u|--ui)
      [[ -n "${2:-}" ]] || { echo "错误: $1 需要参数 swiftui 或 uikit" >&2; exit 1; }
      UI_FRAMEWORK="$(echo "$2" | tr '[:upper:]' '[:lower:]')"
      shift 2
      ;;
    -m|--ios|--deployment-target)
      [[ -n "${2:-}" ]] || { echo "错误: $1 需要版本号，如 15.0" >&2; exit 1; }
      IOS_MIN="$2"
      shift 2
      ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do POSITIONAL+=("$1"); shift; done
      break
      ;;
    -*)
      echo "错误: 未知选项: $1" >&2
      usage
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

set -- "${POSITIONAL[@]}"

[[ ${1:-} == "" ]] && usage

PROJECT_NAME="$1"
BUNDLE_ID="${2:-com.example.${PROJECT_NAME}}"
OUT_DIR="${3:-.}"

case "$LANGUAGE" in
  swift|objc) ;;
  *)
    echo "错误: --language 只能是 swift 或 objc（当前: $LANGUAGE）" >&2
    exit 1
    ;;
esac

case "$UI_FRAMEWORK" in
  swiftui|uikit) ;;
  *)
    echo "错误: --ui 只能是 swiftui 或 uikit（当前: $UI_FRAMEWORK）" >&2
    exit 1
    ;;
esac

if [[ "$LANGUAGE" == "objc" && "$UI_FRAMEWORK" == "swiftui" ]]; then
  echo "错误: SwiftUI 仅支持 Swift，请使用 --language swift 或 --ui uikit" >&2
  exit 1
fi

# 项目目录名与 Xcode target 名（避免空格，简化脚本）
if [[ "$PROJECT_NAME" =~ [[:space:]] ]]; then
  echo "错误: 项目名不能包含空格" >&2
  exit 1
fi

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "未找到 xcodegen。请执行: brew install xcodegen" >&2
  exit 1
fi

ROOT="${OUT_DIR%/}/$PROJECT_NAME"
if [[ -e "$ROOT" ]]; then
  echo "错误: 已存在路径: $ROOT" >&2
  exit 1
fi

APP_DIR="$ROOT/$PROJECT_NAME"
mkdir -p "$APP_DIR/Assets.xcassets/AppIcon.appiconset"

# Info.plist 相关：SwiftUI / Scene 与纯 AppDelegate 窗口
if [[ "$UI_FRAMEWORK" == "swiftui" ]]; then
  SCENE_MANIFEST="YES"
else
  SCENE_MANIFEST="NO"
fi

# --- project.yml（XcodeGen）---
{
  echo "name: $PROJECT_NAME"
  echo "options:"
  echo "  bundleIdPrefix: $(echo "$BUNDLE_ID" | sed 's/\.[^.]*$//')"
  echo "  deploymentTarget:"
  echo "    iOS: \"$IOS_MIN\""
  echo "  xcodeVersion: \"15.0\""
  echo "targets:"
  echo "  $PROJECT_NAME:"
  echo "    type: application"
  echo "    platform: iOS"
  echo "    sources:"
  echo "      - path: $PROJECT_NAME"
  echo "    settings:"
  echo "      base:"
  echo "        PRODUCT_BUNDLE_IDENTIFIER: $BUNDLE_ID"
  echo "        GENERATE_INFOPLIST_FILE: YES"
  echo "        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: $SCENE_MANIFEST"
  echo "        INFOPLIST_KEY_UILaunchScreen_Generation: YES"
  echo "        INFOPLIST_KEY_CFBundleDisplayName: $PROJECT_NAME"
  echo "        TARGETED_DEVICE_FAMILY: \"1,2\""
  echo "        CURRENT_PROJECT_VERSION: 1"
  echo "        MARKETING_VERSION: 1.0.0"
  if [[ "$LANGUAGE" == "swift" ]]; then
    echo "        SWIFT_VERSION: \"5.0\""
  fi
} > "$ROOT/project.yml"

if [[ "$LANGUAGE" == "swift" && "$UI_FRAMEWORK" == "swiftui" ]]; then
  cat > "$APP_DIR/${PROJECT_NAME}App.swift" <<SWIFT
import SwiftUI

@main
struct ${PROJECT_NAME}App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
SWIFT

  cat > "$APP_DIR/ContentView.swift" <<'SWIFT'
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, iOS!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
SWIFT

elif [[ "$LANGUAGE" == "swift" && "$UI_FRAMEWORK" == "uikit" ]]; then
  cat > "$APP_DIR/AppDelegate.swift" <<'SWIFT'
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = ViewController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}
SWIFT

  cat > "$APP_DIR/ViewController.swift" <<'SWIFT'
import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = "Hello, iOS!"
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .title2)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
SWIFT

else
  # Objective-C + UIKit
  cat > "$APP_DIR/main.m" <<'OBJC'
#import <UIKit/UIKit.h>
#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
OBJC

  cat > "$APP_DIR/AppDelegate.h" <<'OBJC'
#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end
OBJC

  cat > "$APP_DIR/AppDelegate.m" <<'OBJC'
#import "AppDelegate.h"
#import "ViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [[ViewController alloc] init];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
OBJC

  cat > "$APP_DIR/ViewController.h" <<'OBJC'
#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@end
OBJC

  cat > "$APP_DIR/ViewController.m" <<'OBJC'
#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    UILabel *label = [[UILabel alloc] init];
    label.text = @"Hello, iOS!";
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        [label.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [label.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
    ]];
}

@end
OBJC
fi

# --- 资源目录占位（与 Xcode 默认结构一致）---
cat > "$APP_DIR/Assets.xcassets/Contents.json" <<'JSON'
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSON

cat > "$APP_DIR/Assets.xcassets/AppIcon.appiconset/Contents.json" <<'JSON'
{
  "images" : [],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSON

pushd "$ROOT" >/dev/null
xcodegen generate

# 命令行构建产物（与 README 中 xcodebuild -resultBundlePath 一致）
if [[ -f .gitignore ]]; then
  grep -qxF '.bundle/' .gitignore 2>/dev/null || echo '.bundle/' >> .gitignore
else
  echo '.bundle/' > .gitignore
fi

# --- Cursor / VS Code：buildServer.json + 首次构建（SourceKit-LSP）---
if [[ "${IOSPC_SKIP_IDE_SETUP:-}" != "1" ]]; then
  if command -v xcode-build-server >/dev/null 2>&1; then
    if xcode-build-server config -project "${PROJECT_NAME}.xcodeproj" -scheme "$PROJECT_NAME"; then
      echo "已生成 buildServer.json（供 Cursor/VS Code Swift 扩展与 SourceKit 使用）。"
    else
      echo "提示: xcode-build-server config 未成功，可稍后在本目录手动执行:" >&2
      echo "  xcode-build-server config -project ${PROJECT_NAME}.xcodeproj -scheme $PROJECT_NAME" >&2
    fi
  else
    echo "提示: 未安装 xcode-build-server，Cursor/VS Code 内跳转定义前请执行: brew install xcode-build-server" >&2
    echo "     然后在 \"$ROOT\" 下执行: xcode-build-server config -project ${PROJECT_NAME}.xcodeproj -scheme $PROJECT_NAME" >&2
  fi

  if command -v xcodebuild >/dev/null 2>&1; then
    rm -rf .bundle
    if xcodebuild -quiet \
      -project "${PROJECT_NAME}.xcodeproj" \
      -scheme "$PROJECT_NAME" \
      -destination 'generic/platform=iOS Simulator' \
      -resultBundlePath .bundle \
      build; then
      echo "已执行首次 xcodebuild（.bundle/），便于编辑器解析 Swift 工程。"
    else
      echo "提示: 命令行首次构建未成功。请在 Xcode 中打开工程并执行 Product → Build，再在 Cursor/VS Code 中 Reload Window。" >&2
    fi
  else
    echo "提示: 未找到 xcodebuild，请用 Xcode 完成至少一次 Build 后再在编辑器中使用跳转。" >&2
  fi
else
  echo "已跳过 IDE 准备（IOSPC_SKIP_IDE_SETUP=1）。"
fi

popd >/dev/null

echo ""
echo "已创建: $ROOT"
echo "语言: $LANGUAGE | 界面: $UI_FRAMEWORK | 最低 iOS: $IOS_MIN"
echo "打开工程: open \"$ROOT/$PROJECT_NAME.xcodeproj\""
echo ""
echo "Cursor/VS Code: 请「打开文件夹」选择 \"$ROOT\"（与 .xcodeproj 同级），然后 Reload Window 或 Swift: Restart SourceKit-LSP。"
echo ""
echo "说明: 请在 Xcode 中为 AppIcon 添加图标后再上架。"
