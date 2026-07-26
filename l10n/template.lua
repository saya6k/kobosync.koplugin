-- Template: copy to <locale>.lua and translate the values.
--
-- Keys are the English source strings and must match them byte for byte,
-- placeholders (%1, %2) included; spec/l10n_spec.lua enforces both.
return {
    ["%1 books"] =
        "%1 books",
    ["%1 columns"] =
        "%1 columns",
    ["%1 series, %2 books"] =
        "%1 series, %2 books",
    ["(downloaded only)"] =
        "(downloaded only)",
    ["Browse server library"] =
        "Browse server library",
    ["Cancel"] =
        "Cancel",
    ["Cover grid"] =
        "Cover grid",
    ["Delete"] =
        "Delete",
    ["Download"] =
        "Download",
    ["Download folder: %1"] =
        "Download folder: %1",
    ["Downloaded: %1"] =
        "Downloaded: %1",
    ["Downloads every book in the library and fetches new ones as they arrive; on a first sync that means the whole library. When disabled, syncing only updates the catalog and books are downloaded one at a time from the server library browser."] =
        "Downloads every book in the library and fetches new ones as they arrive; on a first sync that means the whole library. When disabled, syncing only updates the catalog and books are downloaded one at a time from the server library browser.",
    ["Every %1 minutes"] =
        "Every %1 minutes",
    ["Failed downloads: %1"] =
        "Failed downloads: %1",
    ["Full Kobo Sync prefix including the personal token, as shown by your server (calibre-web: Profile → Kobo Sync Token)."] =
        "Full Kobo Sync prefix including the personal token, as shown by your server (calibre-web: Profile → Kobo Sync Token).",
    ["Grid columns: %1"] =
        "Grid columns: %1",
    ["Jump"] =
        "Jump",
    ["Keep"] =
        "Keep",
    ["Keep every book on this device"] =
        "Keep every book on this device",
    ["Kobo Sync"] =
        "Kobo Sync",
    ["Kobo Sync failed: %1"] =
        "Kobo Sync failed: %1",
    ["Kobo Sync finished.\nNew: %1  Changed: %2"] =
        "Kobo Sync finished.\nNew: %1  Changed: %2",
    ["Kobo Sync interrupted: %1\nNew: %2  Changed: %3\n\nSyncing again resumes from here."] =
        "Kobo Sync interrupted: %1\nNew: %2  Changed: %3\n\nSyncing again resumes from here.",
    ["Kobo Sync library"] =
        "Kobo Sync library",
    ["Kobo Sync server URL"] =
        "Kobo Sync server URL",
    ["Kobo Sync stopped.\nNew: %1  Changed: %2\n\nThe next sync resumes from here."] =
        "Kobo Sync stopped.\nNew: %1  Changed: %2\n\nThe next sync resumes from here.",
    ["Kobo Sync: %1 book(s) were removed on the server. Delete the local files?\n\n%2"] =
        "Kobo Sync: %1 book(s) were removed on the server. Delete the local files?\n\n%2",
    ["Kobo Sync: %1 items, page %2…"] =
        "Kobo Sync: %1 items, page %2…",
    ["Kobo Sync: already synchronizing."] =
        "Kobo Sync: already synchronizing.",
    ["Kobo Sync: download %1 book(s) to this device now?"] =
        "Kobo Sync: download %1 book(s) to this device now?",
    ["Kobo Sync: download failed: %1"] =
        "Kobo Sync: download failed: %1",
    ["Kobo Sync: downloading\n%1"] =
        "Kobo Sync: downloading\n%1",
    ["Kobo Sync: downloading %1 of %2\n%3\n\nTap to cancel."] =
        "Kobo Sync: downloading %1 of %2\n%3\n\nTap to cancel.",
    ["Kobo Sync: fetching cover…"] =
        "Kobo Sync: fetching cover…",
    ["Kobo Sync: forget the sync state and catalog?\nDownloaded files are kept. The next synchronization will be a full one."] =
        "Kobo Sync: forget the sync state and catalog?\nDownloaded files are kept. The next synchronization will be a full one.",
    ["Kobo Sync: no cover (%1)"] =
        "Kobo Sync: no cover (%1)",
    ["Kobo Sync: no downloadable format for this book."] =
        "Kobo Sync: no downloadable format for this book.",
    ["Kobo Sync: set the server URL first."] =
        "Kobo Sync: set the server URL first.",
    ["Kobo Sync: state reset."] =
        "Kobo Sync: state reset.",
    ["Kobo Sync: stopping after the current page.\n\nWhat has been synced is kept, and syncing again resumes from here."] =
        "Kobo Sync: stopping after the current page.\n\nWhat has been synced is kept, and syncing again resumes from here.",
    ["Kobo Sync: synchronize"] =
        "Kobo Sync: synchronize",
    ["Kobo Sync: synchronizing…"] =
        "Kobo Sync: synchronizing…",
    ["Kobo Sync: syncing reading progress…"] =
        "Kobo Sync: syncing reading progress…",
    ["Kobo Sync: the server has newer reading progress (%1%). Jump there?"] =
        "Kobo Sync: the server has newer reading progress (%1%). Jump there?",
    ["Matches book titles and series names."] =
        "Matches book titles and series names.",
    ["Missing locally: %1"] =
        "Missing locally: %1",
    ["Not now"] =
        "Not now",
    ["Off"] =
        "Off",
    ["Reading progress: %1 sent, %2 received"] =
        "Reading progress: %1 sent, %2 received",
    ["Reset"] =
        "Reset",
    ["Reset sync"] =
        "Reset sync",
    ["Runs only while Wi-Fi is already on, and only refreshes the catalog: an unattended run never starts downloads, and deletions it finds are held until the next sync you start yourself."] =
        "Runs only while Wi-Fi is already on, and only refreshes the catalog: an unattended run never starts downloads, and deletions it finds are held until the next sync you start yourself.",
    ["Save"] =
        "Save",
    ["Search"] =
        "Search",
    ["Search the server library"] =
        "Search the server library",
    ["Search: %1"] =
        "Search: %1",
    ["Search…"] =
        "Search…",
    ["Server: %1"] =
        "Server: %1",
    ["Set server URL"] =
        "Set server URL",
    ["Show all books"] =
        "Show all books",
    ["Show downloaded only"] =
        "Show downloaded only",
    ["Stay"] =
        "Stay",
    ["Stop synchronizing"] =
        "Stop synchronizing",
    ["Sync automatically: every %1 minutes"] =
        "Sync automatically: every %1 minutes",
    ["Sync automatically: off"] =
        "Sync automatically: off",
    ["Synchronize now"] =
        "Synchronize now",
    ["Synchronizes library and reading progress with a self-hosted Kobo Sync server "] =
        "Synchronizes library and reading progress with a self-hosted Kobo Sync server ",
    ["Text list"] =
        "Text list",
    ["Upload reading progress when closing a book"] =
        "Upload reading progress when closing a book",
    ["cannot write to the cover cache"] =
        "cannot write to the cover cache",
    ["no cover URL for this server"] =
        "no cover URL for this server",
    ["the server took too long to respond"] =
        "the server took too long to respond",
    ["this book was synced before covers were supported"] =
        "this book was synced before covers were supported",
    ["unknown error"] =
        "unknown error",
    ["…and %1 more"] =
        "…and %1 more",
}
