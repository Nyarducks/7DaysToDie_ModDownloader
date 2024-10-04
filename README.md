# 7DaysToDie_ModDownloader
Tool to set up 7 Days To Die mods via shared Google Drive.

### 使い方：
1. このリポジトリをダウンロードして任意の場所で解凍する
2. `setting.ini`ファイルのFILE_PATHに'7 Days To Die'ディレクトリが存在するパスに変更する
3. install.batを実行
4. Google Driveの共有リンクからファイルIDを取得して入力する
5. ラージファイル等でエラーが発生した場合、一度のみ手動で`mods.zip`を配置することで続行可能
6. 処理が完了していれば終了

### 注意：
- 前提mods(`0_TFP_Harmony`)以外は一度削除されます。
- ダウンロードしたファイルは処理完了後に削除されます。
  - 手動で配置した`mods.zip`は削除されません。
- ダウンロード可能なファイルはGoogle Driveで共有されたもののみです。
  - エラーが発生した場合は手動で`mods.zip`を配置する必要があります。

### ユースケース：
- カスタムmodsファイルをGoogle Driveで共有して自動インストール
- mods導入を簡単に行うためのユーティリティツール

### 変更点
- powershell wrapperがUTF-8以外の環境で実行すると異常終了する問題を修正 (v1.2)
- ダウンロードリンク作成時にリンクを出力するように修正 (v1.1)
- 前提MODを除いたmodsファイルを自動で削除する処理を追加 (v1.1)
- 処理の最適化 (v1.2)
- ラージファイルに対応 (v1.3)
