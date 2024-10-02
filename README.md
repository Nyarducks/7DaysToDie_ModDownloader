# 7DaysToDie_ModDownloader
Tool to set up 7 Days To Die mods via shared Google Drive.

### 使い方：
1. このリポジトリをダウンロードして任意の場所で解凍する
2. `config.ini`ファイルのFILE_PATHに'7 Days To Die'ディレクトリが存在するパスに変更する
3. install.batを実行
4. Google Driveの共有リンクからファイルIDを取得して入力する
5. ラージファイル等でエラーが発生した場合、一度のみ手動で`mods.zip`を配置することで続行可能
6. 処理が完了していれば終了

### 注意：
- 基本的に上書きされます。削除したい場合は直接削除してください
- ダウンロードしたファイルは処理完了後に削除されます。
- ダウンロード可能なファイルはGoogle Driveで共有されたもののみです。
  - ラージファイルは手動で`mods.zip`を配置する必要があります。

### ユースケース：
- カスタムmodsファイルをGoogle Driveで共有して自動インストール
- mods導入を簡単に行うためのユーティリティツール
