-- Korean (machine translation, not reviewed by a native speaker).
--
-- Keys are the English source strings and must match them byte for byte,
-- placeholders (%1, %2) included; spec/l10n_spec.lua enforces both.
return {
    ["%1 books"] =
        "%1권",
    ["%1 columns"] =
        "%1열",
    ["%1 series, %2 books"] =
        "%1개 시리즈, %2권",
    ["(downloaded only)"] =
        "(다운로드한 것만)",
    ["Browse server library"] =
        "서버 라이브러리 탐색",
    ["Cancel"] =
        "취소",
    ["Cover grid"] =
        "표지 그리드",
    ["Delete"] =
        "삭제",
    ["Download"] =
        "다운로드",
    ["Download folder: %1"] =
        "다운로드 폴더: %1",
    ["Downloaded: %1"] =
        "다운로드함: %1",
    ["Downloads every book in the library and fetches new ones as they arrive; on a first sync that means the whole library. When disabled, syncing only updates the catalog and books are downloaded one at a time from the server library browser."] =
        "라이브러리의 모든 책을 내려받고 새 책이 추가될 때마다 계속 가져옵니다. 첫 동기화에서는 서재 전체가 대상입니다. 끄면 동기화는 목록만 갱신하고, 책은 서버 라이브러리 탐색 화면에서 한 권씩 내려받습니다.",
    ["Every %1 minutes"] =
        "%1분마다",
    ["Failed downloads: %1"] =
        "다운로드 실패: %1",
    ["Full Kobo Sync prefix including the personal token, as shown by your server (calibre-web: Profile → Kobo Sync Token)."] =
        "서버가 표시하는 개인 토큰을 포함한 Kobo Sync 전체 주소 (calibre-web: 프로필 → Kobo Sync 토큰).",
    ["Grid columns: %1"] =
        "그리드 열 수: %1",
    ["Jump"] =
        "이동",
    ["Keep"] =
        "유지",
    ["Keep every book on this device"] =
        "이 기기에 모든 책 유지",
    ["Kobo Sync"] =
        "Kobo Sync",
    ["Kobo Sync failed: %1"] =
        "Kobo Sync 실패: %1",
    ["Kobo Sync finished.\nNew: %1  Changed: %2"] =
        "Kobo Sync 완료.\n새로 추가: %1  변경: %2",
    ["Kobo Sync interrupted: %1\nNew: %2  Changed: %3\n\nSyncing again resumes from here."] =
        "Kobo Sync 중단됨: %1\n새로 추가: %2  변경: %3\n\n다시 동기화하면 여기서 이어집니다.",
    ["Kobo Sync library"] =
        "Kobo Sync 라이브러리",
    ["Kobo Sync server URL"] =
        "Kobo Sync 서버 주소",
    ["Kobo Sync stopped.\nNew: %1  Changed: %2\n\nThe next sync resumes from here."] =
        "Kobo Sync 중지됨.\n새로 추가: %1  변경: %2\n\n다음 동기화가 여기서 이어집니다.",
    ["Kobo Sync: %1 book(s) were removed on the server. Delete the local files?\n\n%2"] =
        "Kobo Sync: 서버에서 %1권이 제거되었습니다. 기기의 파일도 삭제할까요?\n\n%2",
    ["Kobo Sync: %1 items, page %2…"] =
        "Kobo Sync: %1개 항목, %2페이지…",
    ["Kobo Sync: already synchronizing."] =
        "Kobo Sync: 이미 동기화 중입니다.",
    ["Kobo Sync: download %1 book(s) to this device now?"] =
        "Kobo Sync: %1권을 지금 이 기기로 내려받을까요?",
    ["Kobo Sync: download failed: %1"] =
        "Kobo Sync: 다운로드 실패: %1",
    ["Kobo Sync: downloading\n%1"] =
        "Kobo Sync: 내려받는 중\n%1",
    ["Kobo Sync: downloading %1 of %2\n%3\n\nTap to cancel."] =
        "Kobo Sync: %2권 중 %1권 내려받는 중\n%3\n\n탭하면 취소합니다.",
    ["Kobo Sync: fetching cover…"] =
        "Kobo Sync: 표지를 가져오는 중…",
    ["Kobo Sync: forget the sync state and catalog?\nDownloaded files are kept. The next synchronization will be a full one."] =
        "Kobo Sync: 동기화 상태와 목록을 지울까요?\n내려받은 파일은 유지됩니다. 다음 동기화는 전체 동기화가 됩니다.",
    ["Kobo Sync: no cover (%1)"] =
        "Kobo Sync: 표지 없음 (%1)",
    ["Kobo Sync: no downloadable format for this book."] =
        "Kobo Sync: 이 책은 내려받을 수 있는 형식이 없습니다.",
    ["Kobo Sync: set the server URL first."] =
        "Kobo Sync: 서버 주소를 먼저 설정하세요.",
    ["Kobo Sync: state reset."] =
        "Kobo Sync: 상태를 초기화했습니다.",
    ["Kobo Sync: stopping after the current page.\n\nWhat has been synced is kept, and syncing again resumes from here."] =
        "Kobo Sync: 현재 페이지까지 마치고 중지합니다.\n\n지금까지 동기화한 내용은 유지되며, 다시 동기화하면 여기서 이어집니다.",
    ["Kobo Sync: synchronize"] =
        "Kobo Sync: 동기화",
    ["Kobo Sync: synchronizing…"] =
        "Kobo Sync: 동기화 중…",
    ["Kobo Sync: syncing reading progress…"] =
        "Kobo Sync: 읽기 진행률 동기화 중…",
    ["Kobo Sync: the server has newer reading progress (%1%). Jump there?"] =
        "Kobo Sync: 서버에 더 최근 읽기 진행률(%1%)이 있습니다. 그 위치로 이동할까요?",
    ["Matches book titles and series names."] =
        "책 제목과 시리즈 이름에서 찾습니다.",
    ["Missing locally: %1"] =
        "기기에 없음: %1",
    ["Not now"] =
        "나중에",
    ["Off"] =
        "끔",
    ["Reading progress: %1 sent, %2 received"] =
        "읽기 진행률: %1개 보냄, %2개 받음",
    ["Reset"] =
        "초기화",
    ["Reset sync"] =
        "동기화 초기화",
    ["Runs only while Wi-Fi is already on, and only refreshes the catalog: an unattended run never starts downloads, and deletions it finds are held until the next sync you start yourself."] =
        "Wi-Fi가 이미 켜져 있을 때만 실행되며 목록만 갱신합니다. 자동 실행은 다운로드를 시작하지 않고, 발견한 삭제 항목은 직접 시작한 다음 동기화까지 보류됩니다.",
    ["Save"] =
        "저장",
    ["Search"] =
        "검색",
    ["Search the server library"] =
        "서버 라이브러리 검색",
    ["Search: %1"] =
        "검색: %1",
    ["Search…"] =
        "검색…",
    ["Server: %1"] =
        "서버: %1",
    ["Set server URL"] =
        "서버 주소 설정",
    ["Show all books"] =
        "모든 책 보기",
    ["Show downloaded only"] =
        "다운로드한 것만 보기",
    ["Stay"] =
        "머무르기",
    ["Stop synchronizing"] =
        "동기화 중지",
    ["Sync automatically: every %1 minutes"] =
        "자동 동기화: %1분마다",
    ["Sync automatically: off"] =
        "자동 동기화: 끔",
    ["Synchronize now"] =
        "지금 동기화",
    ["Synchronizes library and reading progress with a self-hosted Kobo Sync server "] =
        "자체 호스팅 Kobo Sync 서버와 서재 및 읽기 진행률을 동기화합니다 ",
    ["Text list"] =
        "텍스트 목록",
    ["Upload reading progress when closing a book"] =
        "책을 닫을 때 읽기 진행률 업로드",
    ["cannot write to the cover cache"] =
        "표지 캐시에 쓸 수 없습니다",
    ["no cover URL for this server"] =
        "이 서버에는 표지 주소가 없습니다",
    ["the server took too long to respond"] =
        "서버 응답이 너무 오래 걸렸습니다",
    ["this book was synced before covers were supported"] =
        "이 책은 표지 지원 이전에 동기화되었습니다",
    ["unknown error"] =
        "알 수 없는 오류",
    ["…and %1 more"] =
        "…외 %1권",
}
