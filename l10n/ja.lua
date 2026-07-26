-- Japanese (machine translation, not reviewed by a native speaker).
--
-- Keys are the English source strings and must match them byte for byte,
-- placeholders (%1, %2) included; spec/l10n_spec.lua enforces both.
return {
    ["%1 books"] =
        "%1 冊",
    ["%1 columns"] =
        "%1 列",
    ["%1 series, %2 books"] =
        "%1 シリーズ、%2 冊",
    ["(downloaded only)"] =
        "（ダウンロード済みのみ）",
    ["Browse server library"] =
        "サーバーのライブラリを閲覧",
    ["Cancel"] =
        "キャンセル",
    ["Cover grid"] =
        "表紙グリッド",
    ["Delete"] =
        "削除",
    ["Download"] =
        "ダウンロード",
    ["Download all %1 books"] =
        "%1 冊すべてダウンロード",
    ["Download folder: %1"] =
        "ダウンロード先: %1",
    ["Downloaded: %1"] =
        "ダウンロード済み: %1",
    ["Downloads every book in the library and fetches new ones as they arrive; on a first sync that means the whole library. When disabled, syncing only updates the catalog and books are downloaded one at a time from the server library browser."] =
        "ライブラリのすべての本をダウンロードし、新しい本が追加されるたびに取得します。初回同期ではライブラリ全体が対象になります。無効にすると同期はカタログの更新のみを行い、本はサーバーライブラリの閲覧画面から 1 冊ずつダウンロードします。",
    ["Every %1 minutes"] =
        "%1 分ごと",
    ["Failed downloads: %1"] =
        "ダウンロード失敗: %1",
    ["Failed: %1"] =
        "失敗: %1",
    ["Full Kobo Sync prefix including the personal token, as shown by your server (calibre-web: Profile → Kobo Sync Token)."] =
        "サーバーが表示する、個人トークンを含む Kobo Sync の完全なプレフィックス（calibre-web: プロフィール → Kobo Sync トークン）。",
    ["Grid columns: %1"] =
        "グリッドの列数: %1",
    ["Jump"] =
        "移動",
    ["Keep"] =
        "保持",
    ["Keep every book on this device: %1"] =
        "このデバイスにすべての本を保持: %1",
    ["Kobo Sync"] =
        "Kobo Sync",
    ["Kobo Sync failed: %1"] =
        "Kobo Sync が失敗しました: %1",
    ["Kobo Sync finished.\nNew: %1  Changed: %2"] =
        "Kobo Sync が完了しました。\n新規: %1  変更: %2",
    ["Kobo Sync interrupted: %1\nNew: %2  Changed: %3\n\nSyncing again resumes from here."] =
        "Kobo Sync が中断されました: %1\n新規: %2  変更: %3\n\n再度同期するとここから再開します。",
    ["Kobo Sync library"] =
        "Kobo Sync ライブラリ",
    ["Kobo Sync server URL"] =
        "Kobo Sync サーバー URL",
    ["Kobo Sync stopped.\nNew: %1  Changed: %2\n\nThe next sync resumes from here."] =
        "Kobo Sync を停止しました。\n新規: %1  変更: %2\n\n次回の同期はここから再開します。",
    ["Kobo Sync: %1 book(s) were removed on the server. Delete the local files?\n\n%2"] =
        "Kobo Sync: サーバー上で %1 冊が削除されました。ローカルのファイルを削除しますか?\n\n%2",
    ["Kobo Sync: %1 downloaded."] =
        "Kobo Sync: %1 冊をダウンロードしました。",
    ["Kobo Sync: %1 items, page %2…"] =
        "Kobo Sync: %1 件、%2 ページ目…",
    ["Kobo Sync: already synchronizing."] =
        "Kobo Sync: すでに同期中です。",
    ["Kobo Sync: download %1 book(s) from “%2”?\n\n%3"] =
        "Kobo Sync: 「%2」から %1 冊をダウンロードしますか?\n\n%3",
    ["Kobo Sync: download %1 book(s) to this device now?"] =
        "Kobo Sync: %1 冊をこのデバイスに今すぐダウンロードしますか?",
    ["Kobo Sync: download failed: %1"] =
        "Kobo Sync: ダウンロードに失敗しました: %1",
    ["Kobo Sync: downloading\n%1"] =
        "Kobo Sync: ダウンロード中\n%1",
    ["Kobo Sync: downloading %1 of %2\n%3\n\nTap to cancel."] =
        "Kobo Sync: %2 冊中 %1 冊目をダウンロード中\n%3\n\nタップで中止。",
    ["Kobo Sync: forget the sync state and catalog?\nDownloaded files are kept. The next synchronization will be a full one."] =
        "Kobo Sync: 同期状態とカタログを破棄しますか?\nダウンロード済みのファイルは残ります。次回の同期は完全同期になります。",
    ["Kobo Sync: no downloadable format for this book."] =
        "Kobo Sync: この本にダウンロードできる形式がありません。",
    ["Kobo Sync: set the server URL first."] =
        "Kobo Sync: 先にサーバー URL を設定してください。",
    ["Kobo Sync: state reset."] =
        "Kobo Sync: 状態をリセットしました。",
    ["Kobo Sync: stopping after the current page.\n\nWhat has been synced is kept, and syncing again resumes from here."] =
        "Kobo Sync: 現在のページの完了後に停止します。\n\n同期済みの内容は保持され、再度同期するとここから再開します。",
    ["Kobo Sync: synchronize"] =
        "Kobo Sync: 同期",
    ["Kobo Sync: synchronizing…"] =
        "Kobo Sync: 同期中…",
    ["Kobo Sync: syncing reading progress…"] =
        "Kobo Sync: 読書進捗を同期中…",
    ["Kobo Sync: the server has newer reading progress (%1%). Jump there?"] =
        "Kobo Sync: サーバーに新しい読書進捗があります (%1%)。そこへ移動しますか?",
    ["Kobo Sync: “%1” is already on this device."] =
        "Kobo Sync: 「%1」はすでにこのデバイスにあります。",
    ["Last synced: %1"] =
        "最終同期: %1",
    ["Matches book titles and series names."] =
        "本のタイトルとシリーズ名を検索します。",
    ["Missing locally: %1"] =
        "ローカルに存在しません: %1",
    ["Not now"] =
        "後で",
    ["Off"] =
        "オフ",
    ["On"] =
        "オン",
    ["Reading progress: %1 sent, %2 received"] =
        "読書進捗: %1 件送信、%2 件受信",
    ["Reset"] =
        "リセット",
    ["Reset sync"] =
        "同期をリセット",
    ["Runs only while Wi-Fi is already on, and only refreshes the catalog: an unattended run never starts downloads, and deletions it finds are held until the next sync you start yourself."] =
        "Wi-Fi がすでにオンのときだけ実行され、カタログの更新のみを行います。自動実行がダウンロードを開始することはなく、見つかった削除は次に自分で開始した同期まで保留されます。",
    ["Runs the same unattended sync once the device is online, rather than after a fixed wait: catalog only, and given up on if the network has not appeared within five minutes."] =
        "固定の待ち時間ではなく、デバイスがオンラインになり次第、同じ自動同期を実行します。カタログのみを更新し、5 分以内にネットワークが現れなければ中止します。",
    ["Save"] =
        "保存",
    ["Search"] =
        "検索",
    ["Search the server library"] =
        "サーバーのライブラリを検索",
    ["Search: %1"] =
        "検索: %1",
    ["Search…"] =
        "検索…",
    ["Server: %1"] =
        "サーバー: %1",
    ["Set server URL"] =
        "サーバー URL を設定",
    ["Show all books"] =
        "すべての本を表示",
    ["Show downloaded only"] =
        "ダウンロード済みのみ表示",
    ["Stay"] =
        "そのまま",
    ["Stop synchronizing"] =
        "同期を停止",
    ["Sync automatically: every %1 minutes"] =
        "自動同期: %1 分ごと",
    ["Sync automatically: off"] =
        "自動同期: オフ",
    ["Sync when KOReader starts: %1"] =
        "KOReader の起動時に同期: %1",
    ["Synchronize now"] =
        "今すぐ同期",
    ["Synchronizes library and reading progress with a self-hosted Kobo Sync server "] =
        "セルフホストの Kobo Sync サーバーとライブラリおよび読書進捗を同期します ",
    ["Text list"] =
        "テキスト一覧",
    ["Upload reading progress when closing a book: %1"] =
        "本を閉じるときに読書進捗をアップロード: %1",
    ["cannot write to the cover cache"] =
        "表紙キャッシュに書き込めません",
    ["never"] =
        "未実施",
    ["no cover URL for this server"] =
        "このサーバーには表紙の URL がありません",
    ["the server took too long to respond"] =
        "サーバーの応答に時間がかかりすぎました",
    ["this book was synced before covers were supported"] =
        "この本は表紙対応より前に同期されました",
    ["unknown error"] =
        "不明なエラー",
    ["…and %1 more"] =
        "…ほか %1 件",
}
