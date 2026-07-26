-- Russian (machine translation, not reviewed by a native speaker).
--
-- Keys are the English source strings and must match them byte for byte,
-- placeholders (%1, %2) included; spec/l10n_spec.lua enforces both.
return {
    ["%1 books"] =
        "%1 книг",
    ["%1 columns"] =
        "%1 столбцов",
    ["%1 series, %2 books"] =
        "Серий: %1, книг: %2",
    ["(downloaded only)"] =
        "(только загруженные)",
    ["Browse server library"] =
        "Обзор библиотеки сервера",
    ["Cancel"] =
        "Отмена",
    ["Cover grid"] =
        "Сетка обложек",
    ["Delete"] =
        "Удалить",
    ["Download"] =
        "Загрузить",
    ["Download all %1 books"] =
        "Загрузить все %1 книг",
    ["Download folder: %1"] =
        "Папка загрузки: %1",
    ["Downloaded: %1"] =
        "Загружено: %1",
    ["Downloads every book in the library and fetches new ones as they arrive; on a first sync that means the whole library. When disabled, syncing only updates the catalog and books are downloaded one at a time from the server library browser."] =
        "Загружает каждую книгу библиотеки и добавляет новые по мере появления; при первой синхронизации это вся библиотека. Если выключено, синхронизация обновляет только каталог, а книги загружаются по одной из обзора библиотеки сервера.",
    ["Every %1 minutes"] =
        "Каждые %1 минут",
    ["Failed downloads: %1"] =
        "Неудачные загрузки: %1",
    ["Failed: %1"] =
        "Не удалось: %1",
    ["Full Kobo Sync prefix including the personal token, as shown by your server (calibre-web: Profile → Kobo Sync Token)."] =
        "Полный префикс Kobo Sync вместе с личным токеном, как его показывает сервер (calibre-web: Профиль → Токен Kobo Sync).",
    ["Grid columns: %1"] =
        "Столбцов в сетке: %1",
    ["Jump"] =
        "Перейти",
    ["Keep"] =
        "Оставить",
    ["Keep every book on this device: %1"] =
        "Хранить все книги на этом устройстве: %1",
    ["Kobo Sync"] =
        "Kobo Sync",
    ["Kobo Sync failed: %1"] =
        "Сбой Kobo Sync: %1",
    ["Kobo Sync finished.\nNew: %1  Changed: %2"] =
        "Kobo Sync завершён.\nНовых: %1  Изменённых: %2",
    ["Kobo Sync interrupted: %1\nNew: %2  Changed: %3\n\nSyncing again resumes from here."] =
        "Kobo Sync прерван: %1\nНовых: %2  Изменённых: %3\n\nПовторная синхронизация продолжится отсюда.",
    ["Kobo Sync library"] =
        "Библиотека Kobo Sync",
    ["Kobo Sync server URL"] =
        "URL сервера Kobo Sync",
    ["Kobo Sync stopped.\nNew: %1  Changed: %2\n\nThe next sync resumes from here."] =
        "Kobo Sync остановлен.\nНовых: %1  Изменённых: %2\n\nСледующая синхронизация продолжится отсюда.",
    ["Kobo Sync: %1 book(s) were removed on the server. Delete the local files?\n\n%2"] =
        "Kobo Sync: %1 книг(и) удалено на сервере. Удалить локальные файлы?\n\n%2",
    ["Kobo Sync: %1 downloaded."] =
        "Kobo Sync: загружено %1.",
    ["Kobo Sync: %1 items, page %2…"] =
        "Kobo Sync: %1 элементов, страница %2…",
    ["Kobo Sync: already synchronizing."] =
        "Kobo Sync: синхронизация уже выполняется.",
    ["Kobo Sync: download %1 book(s) from “%2”?\n\n%3"] =
        "Kobo Sync: загрузить %1 книг(и) из «%2»?\n\n%3",
    ["Kobo Sync: download %1 book(s) to this device now?"] =
        "Kobo Sync: загрузить %1 книг(и) на это устройство сейчас?",
    ["Kobo Sync: download failed: %1"] =
        "Kobo Sync: не удалось загрузить: %1",
    ["Kobo Sync: downloading\n%1"] =
        "Kobo Sync: загрузка\n%1",
    ["Kobo Sync: downloading %1 of %2\n%3\n\nTap to cancel."] =
        "Kobo Sync: загрузка %1 из %2\n%3\n\nНажмите, чтобы отменить.",
    ["Kobo Sync: forget the sync state and catalog?\nDownloaded files are kept. The next synchronization will be a full one."] =
        "Kobo Sync: забыть состояние синхронизации и каталог?\nЗагруженные файлы сохранятся. Следующая синхронизация будет полной.",
    ["Kobo Sync: no downloadable format for this book."] =
        "Kobo Sync: нет доступного для загрузки формата этой книги.",
    ["Kobo Sync: set the server URL first."] =
        "Kobo Sync: сначала укажите URL сервера.",
    ["Kobo Sync: state reset."] =
        "Kobo Sync: состояние сброшено.",
    ["Kobo Sync: stopping after the current page.\n\nWhat has been synced is kept, and syncing again resumes from here."] =
        "Kobo Sync: остановка после текущей страницы.\n\nВсё уже синхронизированное сохраняется, а повторная синхронизация продолжится отсюда.",
    ["Kobo Sync: synchronize"] =
        "Kobo Sync: синхронизировать",
    ["Kobo Sync: synchronizing…"] =
        "Kobo Sync: синхронизация…",
    ["Kobo Sync: syncing reading progress…"] =
        "Kobo Sync: синхронизация прогресса чтения…",
    ["Kobo Sync: the server has newer reading progress (%1%). Jump there?"] =
        "Kobo Sync: на сервере более новый прогресс чтения (%1 %). Перейти туда?",
    ["Kobo Sync: “%1” is already on this device."] =
        "Kobo Sync: «%1» уже есть на этом устройстве.",
    ["Last synced: %1"] =
        "Последняя синхронизация: %1",
    ["Matches book titles and series names."] =
        "Ищет по названиям книг и серий.",
    ["Missing locally: %1"] =
        "Отсутствует локально: %1",
    ["Not now"] =
        "Не сейчас",
    ["Off"] =
        "Выключено",
    ["On"] =
        "Вкл.",
    ["Reading progress: %1 sent, %2 received"] =
        "Прогресс чтения: отправлено %1, получено %2",
    ["Reset"] =
        "Сбросить",
    ["Reset sync"] =
        "Сбросить синхронизацию",
    ["Runs only while Wi-Fi is already on, and only refreshes the catalog: an unattended run never starts downloads, and deletions it finds are held until the next sync you start yourself."] =
        "Выполняется только при уже включённом Wi-Fi и обновляет лишь каталог: автоматический запуск никогда не начинает загрузки, а найденные удаления ждут следующей синхронизации, запущенной вами.",
    ["Runs the same unattended sync once the device is online, rather than after a fixed wait: catalog only, and given up on if the network has not appeared within five minutes."] =
        "Запускает ту же автоматическую синхронизацию, как только устройство окажется в сети, а не через фиксированную паузу: только каталог, и отменяется, если сеть не появилась за пять минут.",
    ["Save"] =
        "Сохранить",
    ["Search"] =
        "Искать",
    ["Search the server library"] =
        "Поиск в библиотеке сервера",
    ["Search: %1"] =
        "Поиск: %1",
    ["Search…"] =
        "Поиск…",
    ["Server: %1"] =
        "Сервер: %1",
    ["Set server URL"] =
        "Указать URL сервера",
    ["Show all books"] =
        "Показать все книги",
    ["Show downloaded only"] =
        "Показать только загруженные",
    ["Stay"] =
        "Остаться",
    ["Stop synchronizing"] =
        "Остановить синхронизацию",
    ["Sync automatically: every %1 minutes"] =
        "Автоматическая синхронизация: каждые %1 минут",
    ["Sync automatically: off"] =
        "Автоматическая синхронизация: выключена",
    ["Sync when KOReader starts: %1"] =
        "Синхронизировать при запуске KOReader: %1",
    ["Synchronize now"] =
        "Синхронизировать сейчас",
    ["Synchronizes library and reading progress with a self-hosted Kobo Sync server "] =
        "Синхронизирует библиотеку и прогресс чтения с собственным сервером Kobo Sync ",
    ["Text list"] =
        "Текстовый список",
    ["Upload reading progress when closing a book: %1"] =
        "Отправлять прогресс чтения при закрытии книги: %1",
    ["cannot write to the cover cache"] =
        "не удалось записать в кэш обложек",
    ["never"] =
        "никогда",
    ["no cover URL for this server"] =
        "нет URL обложки для этого сервера",
    ["the server took too long to respond"] =
        "сервер отвечал слишком долго",
    ["this book was synced before covers were supported"] =
        "эта книга синхронизирована до появления поддержки обложек",
    ["unknown error"] =
        "неизвестная ошибка",
    ["…and %1 more"] =
        "… и ещё %1",
}
