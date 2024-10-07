@powershell -NoProfile -ExecutionPolicy Unrestricted "$s=[scriptblock]::create((gc \"%~f0\" -Encoding UTF8|?{$_.readcount -gt 1})-join\"`n\");&$s" %*&goto:eof
# This is a magic of quick web requests.
$ProgressPreference = 'SilentlyContinue'
$TEST_EXTRACTION_PATH = './temp'
$STEPS=8
$ARCHIVE_FILE = 'mods.zip'

# ダウンロードリンク作成処理
function createSharedDriveLink($fileId) {
    return "https://drive.usercontent.google.com/download?id=${fileId}"
}
# 異常終了処理
function panic { pause; exit 1 }
# 遅延処理
function withDelay { sleep 1 }
# テストディレクトリ削除
function cleanTestDirectory { Remove-Item -Recurse -Force -Path "${TEST_EXTRACTION_PATH}" 2>$null }

# 設定ファイルから設定値を読み込む
Write-Host "[1/${STEPS}] 設定ファイルから設定値を読み込み中..."; withDelay
$SETTING_FILE = 'setting.ini'
if (Test-Path $SETTING_FILE) {} else {
    Write-Warning "[1.1/${STEPS}] [エラー] 設定ファイルが見つかりません：${SETTING_FILE}"; panic
}

$CONFIG_STORE = (Get-Content -Path "${SETTING_FILE}" -Raw -Encoding UTF8).Replace('\', '\\') | ConvertFrom-StringData
Write-Host "[1.1/${STEPS}] 設定中のファイルパス: $($CONFIG_STORE.FILE_PATH)"
Write-Host "[1.1/${STEPS}] 設定中のファイルID: $($CONFIG_STORE.FILE_ID)"
Write-Host "[1/${STEPS}] 読み込みが完了しました。"

# ディレクトリチェック
Write-Host "[2/${STEPS}] ファイルパスの存在チェック中..."; withDelay
if (Test-Path $($CONFIG_STORE.FILE_PATH)) {
    Write-Host "[2.1/${STEPS}] 設定されたディレクトリは存在しています。"
} else {
    Write-Warning "[2.1/${STEPS}] 設定されたディレクトリは存在しません。：$($CONFIG_STORE.FILE_PATH)"; panic
}
Write-Host "[2/${STEPS}] ファイルパスの存在チェックが完了しました。"
# 7 Days To Dieが存在しているか確認
$APP_NAME = '7DaysToDie.exe'
$APP_FILE = Join-Path $($CONFIG_STORE.FILE_PATH) "${APP_NAME}"
$MODS_DIRECTORY = Join-Path $($CONFIG_STORE.FILE_PATH) 'Mods'
Write-Host "[3/${STEPS}] 7 Days To Dieの存在チェック中..."; withDelay
if (Test-Path ${APP_FILE}) {
    Write-Host "[3.1/${STEPS}] 設定されたディレクトリ先に${APP_NAME}が存在しています。"
} else {
    Write-Warning "[3.1/${STEPS}] 設定されたディレクトリ先に${APP_NAME}が存在しません。: ${APP_FILE}"; panic
}
Write-Host "[3/${STEPS}] 7 Days To Dieの存在チェックが完了しました。"

# ファイルIDを取得してダウンロードリンクを作成
Write-Host "[4/${STEPS}] Modsのダウンロードリンクを作成中..."; withDelay
$DRIVE_FILE_ID = $CONFIG_STORE.FILE_ID
$CLOUD_ARCHIVE_FILE = 'cloudmods.zip'
$DRIVE_DOWNLOAD_LINK = "$(createSharedDriveLink ${DRIVE_FILE_ID})"
Write-Host "[4/${STEPS}] Modsのダウンロードリンクを作成しました。"

# リンクからダウンロード実行してファイルチェック
Write-Host "[5/${STEPS}] Modsをダウンロード中..."
Write-Host "[5.1/${STEPS}] リクエストURL: ${DRIVE_DOWNLOAD_LINK}"
Invoke-WebRequest -Uri "${DRIVE_DOWNLOAD_LINK}" -OutFile ${CLOUD_ARCHIVE_FILE}
$RESULT_CODE = $?
if (${RESULT_CODE}) {
    # ファイル解凍チェック1回目
    try {
        Write-Host "[5.2/${STEPS}] ファイルの解凍中..."; withDelay
        cleanTestDirectory
        Expand-Archive -Path "${CLOUD_ARCHIVE_FILE}" -DestinationPath "${TEST_EXTRACTION_PATH}" -Force
        Write-Host "[5.2/${STEPS}] ファイルの解凍に成功しました。"
    } catch {
        Write-Warning "[5.2/${STEPS}] ファイルの解凍に失敗しました。ラージファイルダウンロード処理に切り替えます。"
        Write-Host "[5.3/${STEPS}] ダウンロード処理のリクエストとセッション情報を作成中..."; withDelay
        $RESPONSE = Invoke-WebRequest -Uri "${DRIVE_DOWNLOAD_LINK}" -SessionVariable session
        Write-Host "[5.3/${STEPS}] 取得完了しました。"
        Write-Host "[5.4/${STEPS}] レスポンス情報から確認コードを取得中..."; withDelay
        $CONFIRM = [regex]::Match($RESPONSE.Content, 'name="confirm"\s+value="([^"]+)"').Groups[1].Value
        $AUTHORISED_URL = "${DRIVE_DOWNLOAD_LINK}&authuser=0&confirm=${CONFIRM}"
        Write-Host "[5.4/${STEPS}] 確認コードの取得が完了しました。confirm=${CONFIRM}"
        Write-Host "[5.5/${STEPS}] ダウンロード処理を再開中..."; withDelay
        Write-Host "[5.5/${STEPS}] リクエストURL: ${AUTHORISED_URL}"
        Write-Host "[5.5/${STEPS}] セッション情報: ${session}"; withDelay
        Invoke-WebRequest -Uri "${AUTHORISED_URL}" -OutFile "${CLOUD_ARCHIVE_FILE}" -WebSession ${session}
        # ファイル解凍チェック2回目
        try {
            Write-Host "[5.6/${STEPS}] ファイルの解凍中..."; withDelay
            cleanTestDirectory
            Expand-Archive -Path "${CLOUD_ARCHIVE_FILE}" -DestinationPath "${TEST_EXTRACTION_PATH}" -Force
            Write-Host "[5.6/${STEPS}] ファイルの解凍に成功しました。"; withDelay
        } catch {
            Write-Warning "[5.6/${STEPS}] ファイルの解凍に失敗しました。ダウンロードリンクが対応していない可能性があります。"
            Write-Host '処理を終了します。'; panic
        }
    }
} else {
    # ダウンロード処理に失敗した場合、ファイルを削除する
    Remove-Item -Path "${CLOUD_ARCHIVE_FILE}"
    Write-Warning "[5.1/${STEPS}] リクエストに失敗しました。ファイルIDが正しいか確認してください。: ${DRIVE_FILE_ID}"; withDelay
    Write-Host "[5.1/${STEPS}] リンクが対応していない場合、手動で${ARCHIVE_FILE}をここに配置して続行してください。: $(pwd)"; explorer $(pwd); pause
    Write-Host "[5.2/${STEPS}] Modsを取得中..."; withDelay
    if (Test-Path "${ARCHIVE_FILE}") {
        Write-Host "[5.2/${STEPS}] Modsの取得が完了しました。"
        # ファイル解凍チェック1回目
        try {
            Write-Host "[5.3/${STEPS}] ファイルの解凍中..."; withDelay
            cleanTestDirectory
            Expand-Archive -Path "${ARCHIVE_FILE}" -DestinationPath "${TEST_EXTRACTION_PATH}" -Force
            Write-Host "[5.3/${STEPS}] ファイルの解凍に成功しました。"
        } catch {
            Write-Warning "[5.3/${STEPS}] ファイルの解凍に失敗しました。処理を終了します。"; panic
        }
    } else {
        Write-Warning "[5.2/${STEPS}] Modsの取得に失敗しました。処理を終了します。"; panic
    }
}

# Mods をクリーンアップ
$DEPENDENCIES_MOD='0_TFP_Harmony'
Write-Host "[6/${STEPS}] クリーンアップ対象Mods:"; withDelay
Get-ChildItem -Path "${MODS_DIRECTORY}" -Exclude "${DEPENDENCIES_MOD}"; withDelay
Write-Host "[6.1/${STEPS}] Modsをクリーンアップ中..."; withDelay
Get-ChildItem -Path "${MODS_DIRECTORY}" -Exclude "${DEPENDENCIES_MOD}" | Remove-Item -Recurse -Force; withDelay
Write-Host "[6/${STEPS}] クリーンアップが完了しました。"; withDelay

# Mods をインストール
Write-Host "[7/${STEPS}] Modsをインストール中..."; withDelay
Write-Host 'インストール対象のMODS:'; Get-ChildItem -Path "${TEST_EXTRACTION_PATH}" -Exclude "${DEPENDENCIES_MOD}"; withDelay
Move-Item -Path "${TEST_EXTRACTION_PATH}/*" -Destination "${MODS_DIRECTORY}"; withDelay
Write-Host 'インストール後のMODS:'; Get-ChildItem -Path "${MODS_DIRECTORY}"; withDelay
cleanTestDirectory
Write-Host "[7/${STEPS}] Modsのインストールが完了しました。"; withDelay

# 完了メッセージ
Write-Host "[8/${STEPS}] 処理が完了しました。"; withDelay
pause
exit 0
