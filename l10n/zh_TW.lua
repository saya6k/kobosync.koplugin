-- Traditional Chinese (machine translation, not reviewed by a native speaker).
--
-- Keys are the English source strings and must match them byte for byte,
-- placeholders (%1, %2) included; spec/l10n_spec.lua enforces both.
return {
    ["%1 books"] =
        "%1 本書",
    ["%1 columns"] =
        "%1 欄",
    ["%1 series, %2 books"] =
        "%1 個系列，%2 本書",
    ["(downloaded only)"] =
        "（僅已下載）",
    ["Browse server library"] =
        "瀏覽伺服器書庫",
    ["Cancel"] =
        "取消",
    ["Cover grid"] =
        "封面格狀檢視",
    ["Delete"] =
        "刪除",
    ["Download"] =
        "下載",
    ["Download folder: %1"] =
        "下載資料夾：%1",
    ["Downloaded: %1"] =
        "已下載：%1",
    ["Downloads every book in the library and fetches new ones as they arrive; on a first sync that means the whole library. When disabled, syncing only updates the catalog and books are downloaded one at a time from the server library browser."] =
        "下載書庫中的每一本書，並在有新書時持續取得；首次同步時這代表整個書庫。關閉後，同步只更新目錄，書籍需在伺服器書庫瀏覽器中逐本下載。",
    ["Every %1 minutes"] =
        "每 %1 分鐘",
    ["Failed downloads: %1"] =
        "下載失敗：%1",
    ["Full Kobo Sync prefix including the personal token, as shown by your server (calibre-web: Profile → Kobo Sync Token)."] =
        "伺服器顯示的完整 Kobo Sync 前綴，包含個人權杖（calibre-web：個人資料 → Kobo Sync 權杖）。",
    ["Grid columns: %1"] =
        "格狀欄數：%1",
    ["Jump"] =
        "跳至",
    ["Keep"] =
        "保留",
    ["Keep every book on this device"] =
        "在本裝置保留所有書籍",
    ["Kobo Sync"] =
        "Kobo Sync",
    ["Kobo Sync failed: %1"] =
        "Kobo Sync 失敗：%1",
    ["Kobo Sync finished.\nNew: %1  Changed: %2"] =
        "Kobo Sync 已完成。\n新增：%1  變更：%2",
    ["Kobo Sync interrupted: %1\nNew: %2  Changed: %3\n\nSyncing again resumes from here."] =
        "Kobo Sync 已中斷：%1\n新增：%2  變更：%3\n\n再次同步將從此處繼續。",
    ["Kobo Sync library"] =
        "Kobo Sync 書庫",
    ["Kobo Sync server URL"] =
        "Kobo Sync 伺服器網址",
    ["Kobo Sync stopped.\nNew: %1  Changed: %2\n\nThe next sync resumes from here."] =
        "Kobo Sync 已停止。\n新增：%1  變更：%2\n\n下次同步將從此處繼續。",
    ["Kobo Sync: %1 book(s) were removed on the server. Delete the local files?\n\n%2"] =
        "Kobo Sync：伺服器上已移除 %1 本書。要刪除本機檔案嗎？\n\n%2",
    ["Kobo Sync: %1 items, page %2…"] =
        "Kobo Sync：%1 個項目，第 %2 頁…",
    ["Kobo Sync: already synchronizing."] =
        "Kobo Sync：已在同步中。",
    ["Kobo Sync: download %1 book(s) to this device now?"] =
        "Kobo Sync：現在要將 %1 本書下載到本裝置嗎？",
    ["Kobo Sync: download failed: %1"] =
        "Kobo Sync：下載失敗：%1",
    ["Kobo Sync: downloading\n%1"] =
        "Kobo Sync：正在下載\n%1",
    ["Kobo Sync: downloading %1 of %2\n%3\n\nTap to cancel."] =
        "Kobo Sync：正在下載第 %1／%2 本\n%3\n\n輕觸即可取消。",
    ["Kobo Sync: fetching cover…"] =
        "Kobo Sync：正在取得封面…",
    ["Kobo Sync: forget the sync state and catalog?\nDownloaded files are kept. The next synchronization will be a full one."] =
        "Kobo Sync：要清除同步狀態與目錄嗎？\n已下載的檔案會保留。下次同步將是完整同步。",
    ["Kobo Sync: no cover (%1)"] =
        "Kobo Sync：無封面（%1）",
    ["Kobo Sync: no downloadable format for this book."] =
        "Kobo Sync：這本書沒有可下載的格式。",
    ["Kobo Sync: set the server URL first."] =
        "Kobo Sync：請先設定伺服器網址。",
    ["Kobo Sync: state reset."] =
        "Kobo Sync：狀態已重設。",
    ["Kobo Sync: stopping after the current page.\n\nWhat has been synced is kept, and syncing again resumes from here."] =
        "Kobo Sync：將在目前頁面完成後停止。\n\n已同步的內容會保留，再次同步將從此處繼續。",
    ["Kobo Sync: synchronize"] =
        "Kobo Sync：同步",
    ["Kobo Sync: synchronizing…"] =
        "Kobo Sync：正在同步…",
    ["Kobo Sync: syncing reading progress…"] =
        "Kobo Sync：正在同步閱讀進度…",
    ["Kobo Sync: the server has newer reading progress (%1%). Jump there?"] =
        "Kobo Sync：伺服器上的閱讀進度較新（%1%）。要跳過去嗎？",
    ["Matches book titles and series names."] =
        "搜尋書名與系列名稱。",
    ["Missing locally: %1"] =
        "本機缺少：%1",
    ["Not now"] =
        "暫不",
    ["Off"] =
        "關閉",
    ["Reading progress: %1 sent, %2 received"] =
        "閱讀進度：已傳送 %1，已接收 %2",
    ["Reset"] =
        "重設",
    ["Reset sync"] =
        "重設同步",
    ["Runs only while Wi-Fi is already on, and only refreshes the catalog: an unattended run never starts downloads, and deletions it finds are held until the next sync you start yourself."] =
        "僅在 Wi-Fi 已開啟時執行，且只重新整理目錄：自動執行絕不會開始下載，發現的刪除會保留到你下次手動同步時再詢問。",
    ["Save"] =
        "儲存",
    ["Search"] =
        "搜尋",
    ["Search the server library"] =
        "搜尋伺服器書庫",
    ["Search: %1"] =
        "搜尋：%1",
    ["Search…"] =
        "搜尋…",
    ["Server: %1"] =
        "伺服器：%1",
    ["Set server URL"] =
        "設定伺服器網址",
    ["Show all books"] =
        "顯示所有書籍",
    ["Show downloaded only"] =
        "僅顯示已下載",
    ["Stay"] =
        "留在此處",
    ["Stop synchronizing"] =
        "停止同步",
    ["Sync automatically: every %1 minutes"] =
        "自動同步：每 %1 分鐘",
    ["Sync automatically: off"] =
        "自動同步：關閉",
    ["Synchronize now"] =
        "立即同步",
    ["Synchronizes library and reading progress with a self-hosted Kobo Sync server "] =
        "與自架 Kobo Sync 伺服器同步書庫與閱讀進度 ",
    ["Text list"] =
        "文字清單",
    ["Upload reading progress when closing a book"] =
        "關閉書籍時上傳閱讀進度",
    ["cannot write to the cover cache"] =
        "無法寫入封面快取",
    ["no cover URL for this server"] =
        "此伺服器沒有封面網址",
    ["the server took too long to respond"] =
        "伺服器回應逾時",
    ["this book was synced before covers were supported"] =
        "這本書是在支援封面之前同步的",
    ["unknown error"] =
        "不明的錯誤",
    ["…and %1 more"] =
        "…還有 %1 本",
}
