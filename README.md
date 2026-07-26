# kobosync.koplugin

A [KOReader](https://github.com/koreader/koreader) plugin that acts as a **Kobo Sync client** for self-hosted book servers — sync your library and reading progress with [calibre-web](https://github.com/janeczku/calibre-web), [Calibre-Web Automated](https://github.com/crocodilestick/Calibre-Web-Automated), [Calibre-Web NextGen](https://github.com/new-usemame/Calibre-Web-NextGen) and other servers implementing the Kobo Sync protocol.

Kobo's sync protocol is normally only spoken by Kobo's stock firmware. This plugin brings it to KOReader on any device (Kobo, Kindle, Android, PocketBook, desktop).

## Features

- **Library sync** — new, changed and removed books are mirrored from the server
  - *Automatic mode*: new books download to your device on every sync
  - *On-demand mode* (for large libraries): sync only updates the catalog; browse the server library on-device — grouped by series, chapters in reading order — and download books as you open them
- **Two-way reading progress sync** — progress and finished/reading status, with newest-wins conflict resolution; queued offline and uploaded on the next sync
- **Jump to server progress** — when a book is opened and the server knows a newer position, KOReader offers to jump there
- **Safe deletions** — books removed on the server are only deleted locally after confirmation
- Bulk-download confirmation on first sync, incremental syncs afterwards, epub preferred over kepub, gesture-assignable sync action

## Installation

1. Download `kobosync.koplugin.zip` from the [latest release](../../releases/latest)
2. Extract it into KOReader's `plugins/` directory so you end up with `plugins/kobosync.koplugin/main.lua`
3. Restart KOReader

Or install it via [appstore.koplugin](https://github.com/omer-faruq/appstore.koplugin).

## Setup

1. On your server, enable Kobo sync and copy your personal Kobo Sync token/URL
   - **calibre-web**: enable *Kobo sync* in the admin settings, then *Profile → Create/View* Kobo Auth URL. The URL looks like `https://your-server/kobo/<token>`
2. In KOReader: *Tools → Kobo Sync → Set server URL* and paste that URL
3. Optionally choose the download folder and mode (*Download new books automatically* on/off)
4. Tap *Synchronize now*

## Notes & limitations

- Reading positions are exchanged as **percentages** (the Kobo protocol's kepub spans cannot be mapped to KOReader positions). The kepub location from other Kobo devices is preserved untouched.
- Tags/shelves, annotations and highlights are not synced (v1).
- The first sync of a large library can take a while; you will be asked before bulk downloads start.
- *Reset sync* (in the menu) forgets the catalog and sync token but keeps downloaded files.

## Development

```sh
luarocks install busted luacheck dkjson
luacheck .
busted spec/
./scripts/package.sh   # builds dist/kobosync.koplugin.zip
```

Pure-logic modules (`koboapi.lua`, `syncengine.lua`, `readingstate.lua`, `statestore.lua`) have no KOReader dependencies and are covered by the busted suite; `main.lua` and `browser.lua` integrate with KOReader.

## Releasing

Releases are cut from GitHub, not from a local tag — pushing a tag on its own builds nothing.

1. Merge PRs with Conventional Commit titles (`feat:`, `fix:`, `chore:`); they get labelled automatically and collected into a draft release, which also resolves the next version number
2. Publish the draft from the releases page
3. CI writes the tag's version into `_meta.lua`, builds the zip, attaches it to the release, and commits the same version back to `main`

There is a parallel `-rc.N` draft for prereleases. Publishing one attaches a zip as usual but leaves `main` untouched, and appstore.koplugin never offers a prerelease as an update.

## License

[AGPL-3.0](LICENSE), same as KOReader.
