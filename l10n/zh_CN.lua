-- Simplified Chinese (machine translation, not reviewed by a native speaker).
--
-- Keys are the English source strings and must match them byte for byte,
-- placeholders (%1, %2) included; spec/l10n_spec.lua enforces both.
return {
    ["%1 books"] =
        "%1 本书",
    ["%1 columns"] =
        "%1 列",
    ["%1 series, %2 books"] =
        "%1 个系列，%2 本书",
    ["(downloaded only)"] =
        "（仅已下载）",
    ["Browse server library"] =
        "浏览服务器书库",
    ["Cancel"] =
        "取消",
    ["Cover grid"] =
        "封面网格",
    ["Delete"] =
        "删除",
    ["Download"] =
        "下载",
    ["Download all %1 books"] =
        "下载全部 %1 本",
    ["Download folder: %1"] =
        "下载文件夹：%1",
    ["Downloaded: %1"] =
        "已下载：%1",
    ["Downloads every book in the library and fetches new ones as they arrive; on a first sync that means the whole library. When disabled, syncing only updates the catalog and books are downloaded one at a time from the server library browser."] =
        "下载书库中的每一本书，并在有新书时继续获取；首次同步时这意味着整个书库。关闭后，同步只更新目录，书籍需在服务器书库浏览器中逐本下载。",
    ["Every %1 minutes"] =
        "每 %1 分钟",
    ["Failed downloads: %1"] =
        "下载失败：%1",
    ["Failed: %1"] =
        "失败：%1",
    ["Full Kobo Sync prefix including the personal token, as shown by your server (calibre-web: Profile → Kobo Sync Token)."] =
        "服务器显示的完整 Kobo Sync 前缀，包含个人令牌（calibre-web：个人资料 → Kobo Sync 令牌）。",
    ["Grid columns: %1"] =
        "网格列数：%1",
    ["Jump"] =
        "跳转",
    ["Keep"] =
        "保留",
    ["Keep every book on this device"] =
        "在本设备保留全部书籍",
    ["Kobo Sync"] =
        "Kobo Sync",
    ["Kobo Sync failed: %1"] =
        "Kobo Sync 失败：%1",
    ["Kobo Sync finished.\nNew: %1  Changed: %2"] =
        "Kobo Sync 已完成。\n新增：%1  变更：%2",
    ["Kobo Sync interrupted: %1\nNew: %2  Changed: %3\n\nSyncing again resumes from here."] =
        "Kobo Sync 已中断：%1\n新增：%2  变更：%3\n\n再次同步将从此处继续。",
    ["Kobo Sync library"] =
        "Kobo Sync 书库",
    ["Kobo Sync server URL"] =
        "Kobo Sync 服务器地址",
    ["Kobo Sync stopped.\nNew: %1  Changed: %2\n\nThe next sync resumes from here."] =
        "Kobo Sync 已停止。\n新增：%1  变更：%2\n\n下次同步将从此处继续。",
    ["Kobo Sync: %1 book(s) were removed on the server. Delete the local files?\n\n%2"] =
        "Kobo Sync：服务器上已删除 %1 本书。要删除本地文件吗？\n\n%2",
    ["Kobo Sync: %1 downloaded."] =
        "Kobo Sync：已下载 %1 本。",
    ["Kobo Sync: %1 items, page %2…"] =
        "Kobo Sync：%1 个条目，第 %2 页…",
    ["Kobo Sync: already synchronizing."] =
        "Kobo Sync：已在同步中。",
    ["Kobo Sync: download %1 book(s) from “%2”?\n\n%3"] =
        "Kobo Sync：要从《%2》下载 %1 本书吗？\n\n%3",
    ["Kobo Sync: download %1 book(s) to this device now?"] =
        "Kobo Sync：现在将 %1 本书下载到本设备吗？",
    ["Kobo Sync: download failed: %1"] =
        "Kobo Sync：下载失败：%1",
    ["Kobo Sync: downloading\n%1"] =
        "Kobo Sync：正在下载\n%1",
    ["Kobo Sync: downloading %1 of %2\n%3\n\nTap to cancel."] =
        "Kobo Sync：正在下载第 %1／%2 本\n%3\n\n点击可取消。",
    ["Kobo Sync: forget the sync state and catalog?\nDownloaded files are kept. The next synchronization will be a full one."] =
        "Kobo Sync：要清除同步状态和目录吗？\n已下载的文件会保留。下次同步将是完整同步。",
    ["Kobo Sync: no downloadable format for this book."] =
        "Kobo Sync：该书没有可下载的格式。",
    ["Kobo Sync: set the server URL first."] =
        "Kobo Sync：请先设置服务器地址。",
    ["Kobo Sync: state reset."] =
        "Kobo Sync：状态已重置。",
    ["Kobo Sync: stopping after the current page.\n\nWhat has been synced is kept, and syncing again resumes from here."] =
        "Kobo Sync：将在当前页完成后停止。\n\n已同步的内容会保留，再次同步将从此处继续。",
    ["Kobo Sync: synchronize"] =
        "Kobo Sync：同步",
    ["Kobo Sync: synchronizing…"] =
        "Kobo Sync：正在同步…",
    ["Kobo Sync: syncing reading progress…"] =
        "Kobo Sync：正在同步阅读进度…",
    ["Kobo Sync: the server has newer reading progress (%1%). Jump there?"] =
        "Kobo Sync：服务器上的阅读进度更新（%1%）。要跳转过去吗？",
    ["Kobo Sync: “%1” is already on this device."] =
        "Kobo Sync：《%1》已在本设备上。",
    ["Matches book titles and series names."] =
        "搜索书名和系列名。",
    ["Missing locally: %1"] =
        "本地缺失：%1",
    ["Not now"] =
        "暂不",
    ["Off"] =
        "关闭",
    ["Reading progress: %1 sent, %2 received"] =
        "阅读进度：已发送 %1，已接收 %2",
    ["Reset"] =
        "重置",
    ["Reset sync"] =
        "重置同步",
    ["Runs only while Wi-Fi is already on, and only refreshes the catalog: an unattended run never starts downloads, and deletions it finds are held until the next sync you start yourself."] =
        "仅在 Wi-Fi 已开启时运行，且只刷新目录：自动运行绝不会开始下载，发现的删除会保留到你下次手动同步时再询问。",
    ["Runs the same unattended sync once the device is online, rather than after a fixed wait: catalog only, and given up on if the network has not appeared within five minutes."] =
        "设备一联网就执行同样的自动同步，而不是等待固定时长：只刷新目录；若五分钟内仍无网络则放弃。",
    ["Save"] =
        "保存",
    ["Search"] =
        "搜索",
    ["Search the server library"] =
        "搜索服务器书库",
    ["Search: %1"] =
        "搜索：%1",
    ["Search…"] =
        "搜索…",
    ["Server: %1"] =
        "服务器：%1",
    ["Set server URL"] =
        "设置服务器地址",
    ["Show all books"] =
        "显示全部书籍",
    ["Show downloaded only"] =
        "仅显示已下载",
    ["Stay"] =
        "留在此处",
    ["Stop synchronizing"] =
        "停止同步",
    ["Sync automatically: every %1 minutes"] =
        "自动同步：每 %1 分钟",
    ["Sync automatically: off"] =
        "自动同步：关闭",
    ["Sync when KOReader starts"] =
        "KOReader 启动时同步",
    ["Synchronize now"] =
        "立即同步",
    ["Synchronizes library and reading progress with a self-hosted Kobo Sync server "] =
        "与自建 Kobo Sync 服务器同步书库和阅读进度 ",
    ["Text list"] =
        "文字列表",
    ["Timestamps refreshed: %1"] =
        "已刷新时间戳：%1",
    ["Upload reading progress when closing a book"] =
        "关闭书籍时上传阅读进度",
    ["cannot write to the cover cache"] =
        "无法写入封面缓存",
    ["no cover URL for this server"] =
        "此服务器没有封面地址",
    ["the server took too long to respond"] =
        "服务器响应超时",
    ["this book was synced before covers were supported"] =
        "这本书是在支持封面之前同步的",
    ["unknown error"] =
        "未知错误",
    ["…and %1 more"] =
        "…还有 %1 本",
}
