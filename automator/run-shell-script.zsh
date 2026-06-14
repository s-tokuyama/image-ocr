#!/bin/zsh
set -u

CLI="${HOME}/tool/bin/image-ocr"

if [[ ! -x "$CLI" ]]; then
  /usr/bin/osascript \
    -e 'display alert "画像OCR" message "CLIが見つかりません。~/tool/bin/image-ocr を確認してください。"'
  exit 1
fi

output="$("$CLI" "$@" 2>&1)"
exit_code=$?

printf '%s\n' "$output"

if (( exit_code == 0 )); then
  /usr/bin/osascript \
    -e 'display notification "テキストファイルを保存し、クリップボードへコピーしました。" with title "画像OCR"'
else
  /usr/bin/osascript \
    -e 'display alert "画像OCRに失敗しました" message "'"${output//\"/\\\"}"'"'
fi

exit "$exit_code"
