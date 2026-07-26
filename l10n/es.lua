-- Spanish (machine translation, not reviewed by a native speaker).
--
-- Keys are the English source strings and must match them byte for byte,
-- placeholders (%1, %2) included; spec/l10n_spec.lua enforces both.
return {
    ["%1 books"] =
        "%1 libros",
    ["%1 columns"] =
        "%1 columnas",
    ["%1 series, %2 books"] =
        "%1 series, %2 libros",
    ["(downloaded only)"] =
        "(solo descargados)",
    ["Browse server library"] =
        "Explorar biblioteca del servidor",
    ["Cancel"] =
        "Cancelar",
    ["Cover grid"] =
        "Cuadrícula de portadas",
    ["Delete"] =
        "Eliminar",
    ["Download"] =
        "Descargar",
    ["Download all %1 books"] =
        "Descargar los %1 libros",
    ["Download folder: %1"] =
        "Carpeta de descargas: %1",
    ["Downloaded: %1"] =
        "Descargados: %1",
    ["Downloads every book in the library and fetches new ones as they arrive; on a first sync that means the whole library. When disabled, syncing only updates the catalog and books are downloaded one at a time from the server library browser."] =
        "Descarga todos los libros de la biblioteca y obtiene los nuevos a medida que llegan; en una primera sincronización eso significa la biblioteca entera. Si se desactiva, la sincronización solo actualiza el catálogo y los libros se descargan de uno en uno desde el explorador de la biblioteca del servidor.",
    ["Every %1 minutes"] =
        "Cada %1 minutos",
    ["Failed downloads: %1"] =
        "Descargas fallidas: %1",
    ["Failed: %1"] =
        "Fallidos: %1",
    ["Full Kobo Sync prefix including the personal token, as shown by your server (calibre-web: Profile → Kobo Sync Token)."] =
        "Prefijo completo de Kobo Sync, incluido el token personal, tal como lo muestra su servidor (calibre-web: Perfil → Token de Kobo Sync).",
    ["Grid columns: %1"] =
        "Columnas de la cuadrícula: %1",
    ["Jump"] =
        "Ir",
    ["Keep"] =
        "Conservar",
    ["Keep every book on this device"] =
        "Mantener todos los libros en este dispositivo",
    ["Kobo Sync"] =
        "Kobo Sync",
    ["Kobo Sync failed: %1"] =
        "Kobo Sync falló: %1",
    ["Kobo Sync finished.\nNew: %1  Changed: %2"] =
        "Kobo Sync finalizado.\nNuevos: %1  Cambiados: %2",
    ["Kobo Sync interrupted: %1\nNew: %2  Changed: %3\n\nSyncing again resumes from here."] =
        "Kobo Sync interrumpido: %1\nNuevos: %2  Cambiados: %3\n\nAl sincronizar de nuevo se retomará desde aquí.",
    ["Kobo Sync library"] =
        "Biblioteca de Kobo Sync",
    ["Kobo Sync server URL"] =
        "URL del servidor Kobo Sync",
    ["Kobo Sync stopped.\nNew: %1  Changed: %2\n\nThe next sync resumes from here."] =
        "Kobo Sync detenido.\nNuevos: %1  Cambiados: %2\n\nLa próxima sincronización se retomará desde aquí.",
    ["Kobo Sync: %1 book(s) were removed on the server. Delete the local files?\n\n%2"] =
        "Kobo Sync: %1 libro(s) se eliminaron en el servidor. ¿Eliminar los archivos locales?\n\n%2",
    ["Kobo Sync: %1 downloaded."] =
        "Kobo Sync: %1 descargados.",
    ["Kobo Sync: %1 items, page %2…"] =
        "Kobo Sync: %1 elementos, página %2…",
    ["Kobo Sync: already synchronizing."] =
        "Kobo Sync: ya se está sincronizando.",
    ["Kobo Sync: download %1 book(s) from “%2”?\n\n%3"] =
        "Kobo Sync: ¿descargar %1 libro(s) de «%2»?\n\n%3",
    ["Kobo Sync: download %1 book(s) to this device now?"] =
        "Kobo Sync: ¿descargar %1 libro(s) en este dispositivo ahora?",
    ["Kobo Sync: download failed: %1"] =
        "Kobo Sync: error al descargar: %1",
    ["Kobo Sync: downloading\n%1"] =
        "Kobo Sync: descargando\n%1",
    ["Kobo Sync: downloading %1 of %2\n%3\n\nTap to cancel."] =
        "Kobo Sync: descargando %1 de %2\n%3\n\nToque para cancelar.",
    ["Kobo Sync: forget the sync state and catalog?\nDownloaded files are kept. The next synchronization will be a full one."] =
        "Kobo Sync: ¿olvidar el estado de sincronización y el catálogo?\nLos archivos descargados se conservan. La próxima sincronización será completa.",
    ["Kobo Sync: no downloadable format for this book."] =
        "Kobo Sync: no hay formato descargable para este libro.",
    ["Kobo Sync: set the server URL first."] =
        "Kobo Sync: primero configure la URL del servidor.",
    ["Kobo Sync: state reset."] =
        "Kobo Sync: estado reiniciado.",
    ["Kobo Sync: stopping after the current page.\n\nWhat has been synced is kept, and syncing again resumes from here."] =
        "Kobo Sync: se detendrá tras la página actual.\n\nLo ya sincronizado se conserva, y al sincronizar de nuevo se retomará desde aquí.",
    ["Kobo Sync: synchronize"] =
        "Kobo Sync: sincronizar",
    ["Kobo Sync: synchronizing…"] =
        "Kobo Sync: sincronizando…",
    ["Kobo Sync: syncing reading progress…"] =
        "Kobo Sync: sincronizando el progreso de lectura…",
    ["Kobo Sync: the server has newer reading progress (%1%). Jump there?"] =
        "Kobo Sync: el servidor tiene un progreso más reciente (%1 %). ¿Ir allí?",
    ["Kobo Sync: “%1” is already on this device."] =
        "Kobo Sync: «%1» ya está en este dispositivo.",
    ["Matches book titles and series names."] =
        "Busca en títulos de libros y nombres de series.",
    ["Missing locally: %1"] =
        "Faltan localmente: %1",
    ["Not now"] =
        "Ahora no",
    ["Off"] =
        "Desactivado",
    ["Reading progress: %1 sent, %2 received"] =
        "Progreso de lectura: %1 enviados, %2 recibidos",
    ["Reset"] =
        "Reiniciar",
    ["Reset sync"] =
        "Reiniciar sincronización",
    ["Runs only while Wi-Fi is already on, and only refreshes the catalog: an unattended run never starts downloads, and deletions it finds are held until the next sync you start yourself."] =
        "Solo se ejecuta con el Wi-Fi ya encendido y solo actualiza el catálogo: una ejecución automática nunca inicia descargas, y las eliminaciones que detecte esperan a la próxima sincronización que usted inicie.",
    ["Runs the same unattended sync once the device is online, rather than after a fixed wait: catalog only, and given up on if the network has not appeared within five minutes."] =
        "Ejecuta la misma sincronización automática en cuanto el dispositivo está en línea, en lugar de tras una espera fija: solo el catálogo, y se abandona si la red no aparece en cinco minutos.",
    ["Save"] =
        "Guardar",
    ["Search"] =
        "Buscar",
    ["Search the server library"] =
        "Buscar en la biblioteca del servidor",
    ["Search: %1"] =
        "Búsqueda: %1",
    ["Search…"] =
        "Buscar…",
    ["Server: %1"] =
        "Servidor: %1",
    ["Set server URL"] =
        "Configurar URL del servidor",
    ["Show all books"] =
        "Mostrar todos los libros",
    ["Show downloaded only"] =
        "Mostrar solo descargados",
    ["Stay"] =
        "Quedarse",
    ["Stop synchronizing"] =
        "Detener la sincronización",
    ["Sync automatically: every %1 minutes"] =
        "Sincronizar automáticamente: cada %1 minutos",
    ["Sync automatically: off"] =
        "Sincronizar automáticamente: desactivado",
    ["Sync when KOReader starts"] =
        "Sincronizar al iniciar KOReader",
    ["Synchronize now"] =
        "Sincronizar ahora",
    ["Synchronizes library and reading progress with a self-hosted Kobo Sync server "] =
        "Sincroniza la biblioteca y el progreso de lectura con un servidor Kobo Sync autoalojado ",
    ["Text list"] =
        "Lista de texto",
    ["Timestamps refreshed: %1"] =
        "Marcas de tiempo actualizadas: %1",
    ["Upload reading progress when closing a book"] =
        "Subir el progreso de lectura al cerrar un libro",
    ["cannot write to the cover cache"] =
        "no se puede escribir en la caché de portadas",
    ["no cover URL for this server"] =
        "no hay URL de portada para este servidor",
    ["the server took too long to respond"] =
        "el servidor tardó demasiado en responder",
    ["this book was synced before covers were supported"] =
        "este libro se sincronizó antes de que hubiera portadas",
    ["unknown error"] =
        "error desconocido",
    ["…and %1 more"] =
        "… y %1 más",
}
