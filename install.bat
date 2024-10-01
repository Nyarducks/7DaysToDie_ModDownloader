@powershell -NoProfile -ExecutionPolicy Unrestricted "$s=[scriptblock]::create((gc \"%~f0\"|?{$_.readcount -gt 1})-join\"`n\");&$s" %*&goto:eof

# 異常終了処理関数
function panic { pause; exit 1 }
# 設定ファイルからファイルパスを読み込む
Write-Host '[1/7] 設定ファイルからファイルパスを読み込み中...'
$SETTING_FILE = 'setting.ini'
if (Test-Path $SETTING_FILE) {} else {
    Write-Warning "[1/7] [エラー] 設定ファイルが見つかりません：${SETTING_FILE}"
    panic
}

$CONFIG_STORE = (Get-Content -Path "${SETTING_FILE}" -Raw -Encoding UTF8).Replace('\', '\\') | ConvertFrom-StringData
Write-Host "[1/7] 設定中のファイルパス: $($CONFIG_STORE.FILE_PATH)"
Write-Host '[1/7] 読み込みが完了しました。'

# ディレクトリチェック
Write-Host '[2/7] ファイルパスの存在チェック中...'
if (Test-Path $($CONFIG_STORE.FILE_PATH)) {
    Write-Host '[2/7] 設定されたディレクトリは存在しています。'
} else {
    Write-Warning "[2/7] 設定されたディレクトリは存在しません。：$($CONFIG_STORE.FILE_PATH)"
    panic
}
Write-Host '[2/7] ファイルパスの存在チェックが完了しました。'
# 7 Days To Dieが存在しているか確認
$APP_NAME = '7DaysToDie.exe'
$APP_FILE = Join-Path $($CONFIG_STORE.FILE_PATH) "${APP_NAME}"
$MODS_DIRECTORY = Join-Path $($CONFIG_STORE.FILE_PATH) 'Mods'
Write-Host '[3/7] 7 Days To Dieの存在チェック中...'
if (Test-Path ${APP_FILE}) {
    Write-Host "[3/7] 設定されたディレクトリ先に${APP_NAME}が存在しています。"
} else {
    Write-Warning "[3/7] 設定されたディレクトリ先に${APP_NAME}が存在しません。: ${APP_FILE}"
    panic
}
Write-Host '[3/7] 7 Days To Dieの存在チェックが完了しました。'

# ファイルIDを入力してダウンロードリンクを作成
Write-Host '[4/7] Modsのダウンロードリンクを作成中...'
$DRIVE_FILE_ID = Read-Host '[4/7] 配布されたModsのファイルID(Google Driveの共有用ファイルID)を入力してください'
$ARCHIVE_FILE = 'mods.zip'
$DRIVE_DOWNLOAD_LINK = "https://drive.usercontent.google.com/u/0/uc?id=${DRIVE_FILE_ID}&export=download"
Write-Host '[4/7] Modsのダウンロードリンクを作成しました。'

# リンクからダウンロード実行してファイルチェック
Write-Host '[5/7] Modsをダウンロード中...'
Invoke-WebRequest -Uri "${DRIVE_DOWNLOAD_LINK}" -OutFile ${ARCHIVE_FILE}
# ファイルチェック
if (Test-Path "${ARCHIVE_FILE}") {
    Write-Host "[5/7] ${ARCHIVE_FILE}は正常にダウンロードされました。"
} else {
    Write-Warning "[5/7] ${ARCHIVE_FILE}のダウンロードに失敗しました。"
    Write-Host "[5/7] ファイルIDが正しいか確認してください。: ${DRIVE_FILE_ID}"
    panic
}
Write-Host '[5/7] Modsのダウンロードが完了しました。'

# mods.zip を展開
Write-Host '[6/7] Modsをインストール中...'
Write-Host "${MODS_DIRECTORY}"
Expand-Archive -Path "${ARCHIVE_FILE}" -DestinationPath "${MODS_DIRECTORY}" -Force
Remove-Item -Path "${ARCHIVE_FILE}"
Write-Host '[6/7] Modsのインストールが完了しました。'

# 完了メッセージ
Write-Host "[7/7] 処理完了しました。"
sleep 3
exit 0
