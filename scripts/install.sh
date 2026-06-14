#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
INSTALL_DIR="${HOME}/tool/bin"
INSTALL_PATH="${INSTALL_DIR}/image-ocr"

cd "$PROJECT_DIR"

echo "Releaseビルドを実行します..."
/usr/bin/swift build -c release

mkdir -p "$INSTALL_DIR"
install -m 755 ".build/release/image-ocr" "$INSTALL_PATH"

echo
echo "インストール完了:"
echo "  $INSTALL_PATH"
echo
echo "確認:"
echo "  $INSTALL_PATH /path/to/image.png"
