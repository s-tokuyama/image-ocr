# image-ocr

macOSのApple Visionを使い、画像から日本語・英語を文字起こしするCLIです。

## 動作

- 選択した画像をApple VisionでOCR
- 元画像と同じフォルダに `元画像名.ocr.txt` を保存
- 認識結果をクリップボードへコピー
- 複数画像をまとめて処理可能
- 完全ローカル処理

## 必要環境

- macOS 13以降
- Xcode Command Line Tools

未導入の場合:

```bash
xcode-select --install
```

## インストール

```bash
cd image-ocr
./scripts/install.sh
```

インストール先:

```text
~/tool/bin/image-ocr
```

## CLIで確認

```bash
~/tool/bin/image-ocr ~/Desktop/screenshot.png
```

生成物:

```text
~/Desktop/screenshot.ocr.txt
```

クリップボードも確認できます。

```bash
pbpaste
```

## Finderのクイックアクションへ登録

1. Automatorを起動
2. 「新規書類」→「クイックアクション」
3. 上部を次のように設定
   - ワークフローが受け取る現在の項目: `イメージファイル`
   - 検索対象: `Finder`
4. 「シェルスクリプトを実行」を追加
5. 設定
   - シェル: `/bin/zsh`
   - 入力の引き渡し方法: `引数として`
6. `automator/run-shell-script.zsh` の内容を貼り付け
7. 「画像を文字起こし」などの名前で保存

Finderで画像を右クリックし、次を選びます。

```text
クイックアクション → 画像を文字起こし
```

表示されない場合は、システム設定のFinder用機能拡張でクイックアクションを有効にしてください。

## 現在の認識設定

```swift
request.recognitionLevel = .accurate
request.recognitionLanguages = ["ja-JP", "en-US"]
request.usesLanguageCorrection = true
```

## 注意点

- Web画面の単一カラムは比較的自然に出力されます。
- 複数カラム、表、サイドバーを含む画面では読み順が崩れることがあります。
- 既存の同名 `.ocr.txt` は上書きします。
- パスワードや個人情報を含む画像も外部送信されません。
