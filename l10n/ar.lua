-- Arabic (machine translation, not reviewed by a native speaker). KOReader handles bidi wrapping through core gettext.
--
-- Keys are the English source strings and must match them byte for byte,
-- placeholders (%1, %2) included; spec/l10n_spec.lua enforces both.
return {
    ["%1 books"] =
        "%1 كتاب",
    ["%1 columns"] =
        "%1 أعمدة",
    ["%1 series, %2 books"] =
        "%1 سلسلة، %2 كتاب",
    ["(downloaded only)"] =
        "(المُنزَّلة فقط)",
    ["Browse server library"] =
        "تصفح مكتبة الخادم",
    ["Cancel"] =
        "إلغاء",
    ["Cover grid"] =
        "شبكة الأغلفة",
    ["Delete"] =
        "حذف",
    ["Download"] =
        "تنزيل",
    ["Download all %1 books"] =
        "تنزيل كل الكتب (%1)",
    ["Download folder: %1"] =
        "مجلد التنزيل: %1",
    ["Downloaded: %1"] =
        "تم التنزيل: %1",
    ["Downloads every book in the library and fetches new ones as they arrive; on a first sync that means the whole library. When disabled, syncing only updates the catalog and books are downloaded one at a time from the server library browser."] =
        "ينزّل كل كتاب في المكتبة ويجلب الجديد فور وصوله؛ في المزامنة الأولى يعني ذلك المكتبة بأكملها. عند التعطيل تُحدِّث المزامنة الفهرس فقط، وتُنزَّل الكتب واحدًا تلو الآخر من متصفح مكتبة الخادم.",
    ["Every %1 minutes"] =
        "كل %1 دقيقة",
    ["Failed downloads: %1"] =
        "تنزيلات فاشلة: %1",
    ["Failed: %1"] =
        "فشل: %1",
    ["Full Kobo Sync prefix including the personal token, as shown by your server (calibre-web: Profile → Kobo Sync Token)."] =
        "بادئة Kobo Sync الكاملة متضمنةً الرمز الشخصي، كما يعرضها الخادم (calibre-web: الملف الشخصي ← رمز Kobo Sync).",
    ["Grid columns: %1"] =
        "أعمدة الشبكة: %1",
    ["Jump"] =
        "انتقال",
    ["Keep"] =
        "إبقاء",
    ["Keep every book on this device"] =
        "الاحتفاظ بكل كتاب على هذا الجهاز",
    ["Kobo Sync"] =
        "Kobo Sync",
    ["Kobo Sync failed: %1"] =
        "فشل Kobo Sync: %1",
    ["Kobo Sync finished.\nNew: %1  Changed: %2"] =
        "اكتملت مزامنة Kobo Sync.\nجديد: %1  متغيّر: %2",
    ["Kobo Sync interrupted: %1\nNew: %2  Changed: %3\n\nSyncing again resumes from here."] =
        "توقفت مزامنة Kobo Sync: %1\nجديد: %2  متغيّر: %3\n\nستكمل المزامنة التالية من هنا.",
    ["Kobo Sync library"] =
        "مكتبة Kobo Sync",
    ["Kobo Sync server URL"] =
        "عنوان خادم Kobo Sync",
    ["Kobo Sync stopped.\nNew: %1  Changed: %2\n\nThe next sync resumes from here."] =
        "أُوقفت مزامنة Kobo Sync.\nجديد: %1  متغيّر: %2\n\nستكمل المزامنة التالية من هنا.",
    ["Kobo Sync: %1 book(s) were removed on the server. Delete the local files?\n\n%2"] =
        "Kobo Sync: أُزيل %1 كتاب من الخادم. هل تحذف الملفات المحلية؟\n\n%2",
    ["Kobo Sync: %1 downloaded."] =
        "Kobo Sync: تم تنزيل %1.",
    ["Kobo Sync: %1 items, page %2…"] =
        "Kobo Sync: %1 عنصر، صفحة %2…",
    ["Kobo Sync: already synchronizing."] =
        "Kobo Sync: المزامنة جارية بالفعل.",
    ["Kobo Sync: download %1 book(s) from “%2”?\n\n%3"] =
        "Kobo Sync: هل تنزّل %1 كتاب من «%2»؟\n\n%3",
    ["Kobo Sync: download %1 book(s) to this device now?"] =
        "Kobo Sync: هل تنزّل %1 كتاب إلى هذا الجهاز الآن؟",
    ["Kobo Sync: download failed: %1"] =
        "Kobo Sync: فشل التنزيل: %1",
    ["Kobo Sync: downloading\n%1"] =
        "Kobo Sync: جارٍ التنزيل\n%1",
    ["Kobo Sync: downloading %1 of %2\n%3\n\nTap to cancel."] =
        "Kobo Sync: تنزيل %1 من %2\n%3\n\nانقر للإلغاء.",
    ["Kobo Sync: forget the sync state and catalog?\nDownloaded files are kept. The next synchronization will be a full one."] =
        "Kobo Sync: هل تريد نسيان حالة المزامنة والفهرس؟\nتبقى الملفات المنزَّلة. ستكون المزامنة التالية كاملة.",
    ["Kobo Sync: no downloadable format for this book."] =
        "Kobo Sync: لا توجد صيغة قابلة للتنزيل لهذا الكتاب.",
    ["Kobo Sync: set the server URL first."] =
        "Kobo Sync: عيّن عنوان الخادم أولًا.",
    ["Kobo Sync: state reset."] =
        "Kobo Sync: أُعيدت الحالة إلى وضعها الأصلي.",
    ["Kobo Sync: stopping after the current page.\n\nWhat has been synced is kept, and syncing again resumes from here."] =
        "Kobo Sync: سيتوقف بعد الصفحة الحالية.\n\nيبقى ما تمت مزامنته، وستكمل المزامنة التالية من هنا.",
    ["Kobo Sync: synchronize"] =
        "Kobo Sync: مزامنة",
    ["Kobo Sync: synchronizing…"] =
        "Kobo Sync: جارٍ المزامنة…",
    ["Kobo Sync: syncing reading progress…"] =
        "Kobo Sync: مزامنة تقدم القراءة…",
    ["Kobo Sync: the server has newer reading progress (%1%). Jump there?"] =
        "Kobo Sync: لدى الخادم تقدم قراءة أحدث (%1%). هل تنتقل إليه؟",
    ["Kobo Sync: “%1” is already on this device."] =
        "Kobo Sync: «%1» موجود بالفعل على هذا الجهاز.",
    ["Matches book titles and series names."] =
        "يبحث في عناوين الكتب وأسماء السلاسل.",
    ["Missing locally: %1"] =
        "مفقود محليًا: %1",
    ["Not now"] =
        "ليس الآن",
    ["Off"] =
        "معطّل",
    ["Reading progress: %1 sent, %2 received"] =
        "تقدم القراءة: أُرسل %1، ووصل %2",
    ["Reset"] =
        "إعادة تعيين",
    ["Reset sync"] =
        "إعادة تعيين المزامنة",
    ["Runs only while Wi-Fi is already on, and only refreshes the catalog: an unattended run never starts downloads, and deletions it finds are held until the next sync you start yourself."] =
        "لا تعمل إلا عندما تكون شبكة Wi-Fi مفعّلة بالفعل، وتحدّث الفهرس فقط: التشغيل التلقائي لا يبدأ أي تنزيل، وما يجده من عمليات حذف يُؤجَّل إلى المزامنة التالية التي تبدأها بنفسك.",
    ["Runs the same unattended sync once the device is online, rather than after a fixed wait: catalog only, and given up on if the network has not appeared within five minutes."] =
        "يشغّل المزامنة التلقائية نفسها فور اتصال الجهاز بالشبكة بدلاً من انتظار مدة ثابتة: الفهرس فقط، ويُصرف النظر عنها إذا لم تظهر الشبكة خلال خمس دقائق.",
    ["Save"] =
        "حفظ",
    ["Search"] =
        "بحث",
    ["Search the server library"] =
        "البحث في مكتبة الخادم",
    ["Search: %1"] =
        "بحث: %1",
    ["Search…"] =
        "بحث…",
    ["Server: %1"] =
        "الخادم: %1",
    ["Set server URL"] =
        "تعيين عنوان الخادم",
    ["Show all books"] =
        "إظهار كل الكتب",
    ["Show downloaded only"] =
        "إظهار المنزَّلة فقط",
    ["Stay"] =
        "البقاء",
    ["Stop synchronizing"] =
        "إيقاف المزامنة",
    ["Sync automatically: every %1 minutes"] =
        "مزامنة تلقائية: كل %1 دقيقة",
    ["Sync automatically: off"] =
        "مزامنة تلقائية: معطّلة",
    ["Sync when KOReader starts"] =
        "المزامنة عند بدء تشغيل KOReader",
    ["Synchronize now"] =
        "مزامنة الآن",
    ["Synchronizes library and reading progress with a self-hosted Kobo Sync server "] =
        "يزامن المكتبة وتقدم القراءة مع خادم Kobo Sync مُستضاف ذاتيًا ",
    ["Text list"] =
        "قائمة نصية",
    ["Timestamps refreshed: %1"] =
        "تم تحديث الطوابع الزمنية: %1",
    ["Upload reading progress when closing a book"] =
        "رفع تقدم القراءة عند إغلاق كتاب",
    ["cannot write to the cover cache"] =
        "تعذّرت الكتابة في ذاكرة الأغلفة",
    ["no cover URL for this server"] =
        "لا يوجد عنوان غلاف لهذا الخادم",
    ["the server took too long to respond"] =
        "استغرق الخادم وقتًا طويلًا للرد",
    ["this book was synced before covers were supported"] =
        "تمت مزامنة هذا الكتاب قبل دعم الأغلفة",
    ["unknown error"] =
        "خطأ غير معروف",
    ["…and %1 more"] =
        "… و%1 غيرها",
}
