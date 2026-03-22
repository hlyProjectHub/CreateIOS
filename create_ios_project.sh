#!/usr/bin/env bash
#
# 初始化完整 iOS App 工程（SwiftUI + 单 Target）。
# 依赖: Xcode 命令行工具 + Homebrew 安装的 xcodegen
#   brew install xcodegen
#
# 用法:
#   ./create_ios_project.sh MyApp
#   ./create_ios_project.sh MyApp com.example.myapp
#   ./create_ios_project.sh MyApp com.example.myapp ~/Projects
#

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

usage() {
  echo "用法: $SCRIPT_NAME <项目名> [Bundle ID] [输出目录]"
  echo "示例: $SCRIPT_NAME HelloApp com.acme.helloapp"
  echo ""
  echo "需先安装: brew install xcodegen"
  exit 1
}

[[ ${1:-} == "" ]] || [[ ${1:-} == -h ]] || [[ ${1:-} == --help ]] && usage

PROJECT_NAME="$1"
BUNDLE_ID="${2:-com.example.${PROJECT_NAME}}"
OUT_DIR="${3:-.}"

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

# --- project.yml（XcodeGen）---
cat > "$ROOT/project.yml" <<YAML
name: $PROJECT_NAME
options:
  bundleIdPrefix: $(echo "$BUNDLE_ID" | sed 's/\.[^.]*$//')
  deploymentTarget:
    iOS: "15.0"
  xcodeVersion: "15.0"
targets:
  $PROJECT_NAME:
    type: application
    platform: iOS
    sources:
      - path: $PROJECT_NAME
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: $BUNDLE_ID
        GENERATE_INFOPLIST_FILE: YES
        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: YES
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
        INFOPLIST_KEY_CFBundleDisplayName: $PROJECT_NAME
        SWIFT_VERSION: "5.0"
        TARGETED_DEVICE_FAMILY: "1,2"
        CURRENT_PROJECT_VERSION: 1
        MARKETING_VERSION: 1.0.0
YAML

# --- SwiftUI 入口 ---
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
popd >/dev/null

echo ""
echo "已创建: $ROOT"
echo "打开工程: open \"$ROOT/$PROJECT_NAME.xcodeproj\""
echo ""
echo "说明: 默认 SwiftUI + iOS 15；请在 Xcode 中为 AppIcon 添加图标后再上架。"
