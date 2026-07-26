-- Italian (machine translation, not reviewed by a native speaker).
--
-- Keys are the English source strings and must match them byte for byte,
-- placeholders (%1, %2) included; spec/l10n_spec.lua enforces both.
return {
    ["%1 books"] =
        "%1 libri",
    ["%1 columns"] =
        "%1 colonne",
    ["%1 series, %2 books"] =
        "%1 serie, %2 libri",
    ["(downloaded only)"] =
        "(solo scaricati)",
    ["Browse server library"] =
        "Sfoglia la libreria del server",
    ["Cancel"] =
        "Annulla",
    ["Cover grid"] =
        "Griglia di copertine",
    ["Delete"] =
        "Elimina",
    ["Download"] =
        "Scarica",
    ["Download all %1 books"] =
        "Scarica tutti i %1 libri",
    ["Download folder: %1"] =
        "Cartella di download: %1",
    ["Downloaded: %1"] =
        "Scaricati: %1",
    ["Downloads every book in the library and fetches new ones as they arrive; on a first sync that means the whole library. When disabled, syncing only updates the catalog and books are downloaded one at a time from the server library browser."] =
        "Scarica ogni libro della libreria e recupera i nuovi man mano che arrivano; alla prima sincronizzazione significa l'intera libreria. Se disattivato, la sincronizzazione aggiorna solo il catalogo e i libri si scaricano uno alla volta dal browser della libreria del server.",
    ["Every %1 minutes"] =
        "Ogni %1 minuti",
    ["Failed downloads: %1"] =
        "Download non riusciti: %1",
    ["Failed: %1"] =
        "Non riusciti: %1",
    ["Full Kobo Sync prefix including the personal token, as shown by your server (calibre-web: Profile → Kobo Sync Token)."] =
        "Prefisso Kobo Sync completo, token personale incluso, come indicato dal server (calibre-web: Profilo → Token Kobo Sync).",
    ["Grid columns: %1"] =
        "Colonne della griglia: %1",
    ["Jump"] =
        "Vai",
    ["Keep"] =
        "Mantieni",
    ["Keep every book on this device: %1"] =
        "Mantieni ogni libro su questo dispositivo: %1",
    ["Kobo Sync"] =
        "Kobo Sync",
    ["Kobo Sync failed: %1"] =
        "Kobo Sync non riuscito: %1",
    ["Kobo Sync finished.\nNew: %1  Changed: %2"] =
        "Kobo Sync completato.\nNuovi: %1  Modificati: %2",
    ["Kobo Sync interrupted: %1\nNew: %2  Changed: %3\n\nSyncing again resumes from here."] =
        "Kobo Sync interrotto: %1\nNuovi: %2  Modificati: %3\n\nUna nuova sincronizzazione riprenderà da qui.",
    ["Kobo Sync library"] =
        "Libreria Kobo Sync",
    ["Kobo Sync server URL"] =
        "URL del server Kobo Sync",
    ["Kobo Sync stopped.\nNew: %1  Changed: %2\n\nThe next sync resumes from here."] =
        "Kobo Sync fermato.\nNuovi: %1  Modificati: %2\n\nLa prossima sincronizzazione riprenderà da qui.",
    ["Kobo Sync: %1 book(s) were removed on the server. Delete the local files?\n\n%2"] =
        "Kobo Sync: %1 libro/i sono stati rimossi sul server. Eliminare i file locali?\n\n%2",
    ["Kobo Sync: %1 downloaded."] =
        "Kobo Sync: %1 scaricati.",
    ["Kobo Sync: %1 items, page %2…"] =
        "Kobo Sync: %1 elementi, pagina %2…",
    ["Kobo Sync: already synchronizing."] =
        "Kobo Sync: sincronizzazione già in corso.",
    ["Kobo Sync: download %1 book(s) from “%2”?\n\n%3"] =
        "Kobo Sync: scaricare %1 libro/i da «%2»?\n\n%3",
    ["Kobo Sync: download %1 book(s) to this device now?"] =
        "Kobo Sync: scaricare %1 libro/i su questo dispositivo ora?",
    ["Kobo Sync: download failed: %1"] =
        "Kobo Sync: download non riuscito: %1",
    ["Kobo Sync: downloading\n%1"] =
        "Kobo Sync: download in corso\n%1",
    ["Kobo Sync: downloading %1 of %2\n%3\n\nTap to cancel."] =
        "Kobo Sync: download %1 di %2\n%3\n\nTocca per annullare.",
    ["Kobo Sync: forget the sync state and catalog?\nDownloaded files are kept. The next synchronization will be a full one."] =
        "Kobo Sync: dimenticare lo stato di sincronizzazione e il catalogo?\nI file scaricati vengono mantenuti. La prossima sincronizzazione sarà completa.",
    ["Kobo Sync: no downloadable format for this book."] =
        "Kobo Sync: nessun formato scaricabile per questo libro.",
    ["Kobo Sync: set the server URL first."] =
        "Kobo Sync: imposta prima l'URL del server.",
    ["Kobo Sync: state reset."] =
        "Kobo Sync: stato reimpostato.",
    ["Kobo Sync: stopping after the current page.\n\nWhat has been synced is kept, and syncing again resumes from here."] =
        "Kobo Sync: interruzione dopo la pagina corrente.\n\nQuanto già sincronizzato viene mantenuto e una nuova sincronizzazione riprenderà da qui.",
    ["Kobo Sync: synchronize"] =
        "Kobo Sync: sincronizza",
    ["Kobo Sync: synchronizing…"] =
        "Kobo Sync: sincronizzazione…",
    ["Kobo Sync: syncing reading progress…"] =
        "Kobo Sync: sincronizzazione dei progressi di lettura…",
    ["Kobo Sync: the server has newer reading progress (%1%). Jump there?"] =
        "Kobo Sync: il server ha progressi più recenti (%1 %). Andare lì?",
    ["Kobo Sync: “%1” is already on this device."] =
        "Kobo Sync: «%1» è già su questo dispositivo.",
    ["Last synced: %1"] =
        "Ultima sincronizzazione: %1",
    ["Matches book titles and series names."] =
        "Cerca nei titoli dei libri e nei nomi delle serie.",
    ["Missing locally: %1"] =
        "Mancanti in locale: %1",
    ["Not now"] =
        "Non ora",
    ["Off"] =
        "Disattivato",
    ["On"] =
        "Attivo",
    ["Reading progress: %1 sent, %2 received"] =
        "Progressi di lettura: %1 inviati, %2 ricevuti",
    ["Reset"] =
        "Reimposta",
    ["Reset sync"] =
        "Reimposta sincronizzazione",
    ["Runs only while Wi-Fi is already on, and only refreshes the catalog: an unattended run never starts downloads, and deletions it finds are held until the next sync you start yourself."] =
        "Viene eseguita solo con il Wi-Fi già attivo e aggiorna solo il catalogo: un'esecuzione automatica non avvia mai download e le eliminazioni rilevate attendono la prossima sincronizzazione avviata da te.",
    ["Runs the same unattended sync once the device is online, rather than after a fixed wait: catalog only, and given up on if the network has not appeared within five minutes."] =
        "Avvia la stessa sincronizzazione automatica appena il dispositivo è online, anziché dopo un'attesa fissa: solo catalogo, e abbandonata se la rete non compare entro cinque minuti.",
    ["Save"] =
        "Salva",
    ["Search"] =
        "Cerca",
    ["Search the server library"] =
        "Cerca nella libreria del server",
    ["Search: %1"] =
        "Ricerca: %1",
    ["Search…"] =
        "Cerca…",
    ["Server: %1"] =
        "Server: %1",
    ["Set server URL"] =
        "Imposta URL del server",
    ["Show all books"] =
        "Mostra tutti i libri",
    ["Show downloaded only"] =
        "Mostra solo scaricati",
    ["Stay"] =
        "Resta",
    ["Stop synchronizing"] =
        "Ferma la sincronizzazione",
    ["Sync automatically: every %1 minutes"] =
        "Sincronizza automaticamente: ogni %1 minuti",
    ["Sync automatically: off"] =
        "Sincronizza automaticamente: disattivato",
    ["Sync when KOReader starts: %1"] =
        "Sincronizza all'avvio di KOReader: %1",
    ["Synchronize now"] =
        "Sincronizza ora",
    ["Synchronizes library and reading progress with a self-hosted Kobo Sync server "] =
        "Sincronizza libreria e progressi di lettura con un server Kobo Sync self-hosted ",
    ["Text list"] =
        "Elenco testuale",
    ["Upload reading progress when closing a book: %1"] =
        "Carica i progressi di lettura alla chiusura di un libro: %1",
    ["cannot write to the cover cache"] =
        "impossibile scrivere nella cache delle copertine",
    ["never"] =
        "mai",
    ["no cover URL for this server"] =
        "nessun URL di copertina per questo server",
    ["the server took too long to respond"] =
        "il server ha impiegato troppo tempo a rispondere",
    ["this book was synced before covers were supported"] =
        "questo libro è stato sincronizzato prima del supporto alle copertine",
    ["unknown error"] =
        "errore sconosciuto",
    ["…and %1 more"] =
        "… e altri %1",
}
