@powershell -NoProfile -ExecutionPolicy Unrestricted "$s=[scriptblock]::create((gc \"%~f0\" -Encoding UTF8|?{$_.readcount -gt 1})-join\"`n\");&$s" %*&goto:eof

# 異常終了処理関数
function panic { pause; exit 1 }
# 遅延処理
function withDelay { sleep 1 }
# 設定ファイルからファイルパスを読み込む
Write-Host '[1/8] 設定ファイルからファイルパスを読み込み中...'; withDelay
$SETTING_FILE = 'setting.ini'
if (Test-Path $SETTING_FILE) {} else {
    Write-Warning "[1/8] [エラー] 設定ファイルが見つかりません：${SETTING_FILE}"; panic
}

$CONFIG_STORE = (Get-Content -Path "${SETTING_FILE}" -Raw -Encoding UTF8).Replace('\', '\\') | ConvertFrom-StringData
Write-Host "[1/8] 設定中のファイルパス: $($CONFIG_STORE.FILE_PATH)"
Write-Host '[1/8] 読み込みが完了しました。'

# ディレクトリチェック
Write-Host '[2/8] ファイルパスの存在チェック中...'; withDelay
if (Test-Path $($CONFIG_STORE.FILE_PATH)) {
    Write-Host '[2/8] 設定されたディレクトリは存在しています。'
} else {
    Write-Warning "[2/8] 設定されたディレクトリは存在しません。：$($CONFIG_STORE.FILE_PATH)"; panic
}
Write-Host '[2/8] ファイルパスの存在チェックが完了しました。'
# 7 Days To Dieが存在しているか確認
$APP_NAME = '7DaysToDie.exe'
$APP_FILE = Join-Path $($CONFIG_STORE.FILE_PATH) "${APP_NAME}"
$MODS_DIRECTORY = Join-Path $($CONFIG_STORE.FILE_PATH) 'Mods'
Write-Host '[3/8] 7 Days To Dieの存在チェック中...'; withDelay
if (Test-Path ${APP_FILE}) {
    Write-Host "[3/8] 設定されたディレクトリ先に${APP_NAME}が存在しています。"
} else {
    Write-Warning "[3/8] 設定されたディレクトリ先に${APP_NAME}が存在しません。: ${APP_FILE}"; panic
}
Write-Host '[3/8] 7 Days To Dieの存在チェックが完了しました。'

# ファイルIDを入力してダウンロードリンクを作成
Write-Host '[4/8] Modsのダウンロードリンクを作成中...'; withDelay
$DRIVE_FILE_ID = Read-Host '[4/8] 配布されたModsのファイルID(Google Driveの共有用ファイルID)を入力してください'
$ARCHIVE_FILE = 'mods.zip'
$DRIVE_DOWNLOAD_LINK = "https://drive.usercontent.google.com/u/0/uc?id=${DRIVE_FILE_ID}&export=download"
Write-Host '[4/8] Modsのダウンロードリンクを作成しました。'
Write-Host "${DRIVE_DOWNLOAD_LINK}"

# リンクからダウンロード実行してファイルチェック
Write-Host '[5/8] Modsをダウンロード中...'
Invoke-WebRequest -Uri "${DRIVE_DOWNLOAD_LINK}" -OutFile ${ARCHIVE_FILE}
$RESULT_CODE = $?
# ダウンロード処理が失敗した場合、削除する
if (${RESULT_CODE}) {
    Remove-Item -Path "${ARCHIVE_FILE}"
}

# ファイルチェック
if (Test-Path "${ARCHIVE_FILE}") {
    Write-Host "[5/8] ${ARCHIVE_FILE}は正常にダウンロードされました。"
    Write-Host '[5/8] Modsのダウンロードが完了しました。'; withDelay
} else {
    Write-Warning "[5/8] ${ARCHIVE_FILE}のダウンロードに失敗しました。"
    Write-Host "[5/8] ファイルIDが正しいか確認してください。: ${DRIVE_FILE_ID}"; withDelay
    Write-Host "[5/8] またはファイルサイズが大きい場合手動で${ARCHIVE_FILE}をここに配置してから続行してください。: $(pwd)"; pause
    Write-Host '[5/8] Modsを取得中...'; withDelay
    if (Test-Path "${ARCHIVE_FILE}") {
        Write-Host '[5/8] Modsの取得が完了しました。'
    } else {
        Write-Warning '[5/8] Modsの取得に失敗しました。終了します。'; panic
    }
}

# Mods をクリーンアップ
$DEPENDENCIES_MOD='0_TFP_Harmony'
Write-Host '[6/8] クリーンアップ対象Mods:'; withDelay
Get-ChildItem -Path "${MODS_DIRECTORY}" -Exclude "${DEPENDENCIES_MOD}"
Write-Host '[6/8] Modsをクリーンアップ中...'; withDelay
Get-ChildItem -Path "${MODS_DIRECTORY}" -Exclude "${DEPENDENCIES_MOD}" | Remove-Item -Recurse -Force
Write-Host '[6/8] クリーンアップが完了しました。'

# mods.zip を展開
Write-Host '[7/8] Modsをインストール中...'; withDelay
Expand-Archive -Path "${ARCHIVE_FILE}" -DestinationPath "${MODS_DIRECTORY}" -Force
Get-ChildItem -Path "${MODS_DIRECTORY}" -Exclude "${DEPENDENCIES_MOD}"
Remove-Item -Path "${ARCHIVE_FILE}"
Write-Host '[7/8] Modsのインストールが完了しました。'; withDelay

# 完了メッセージ
Write-Host "[8/8] 処理完了しました。"
pause
exit 0
