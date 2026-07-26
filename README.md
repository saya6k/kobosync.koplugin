# kobosync.koplugin

A [KOReader](https://github.com/koreader/koreader) plugin that acts as a **Kobo Sync client** for self-hosted book servers — sync your library and reading progress with [calibre-web](https://github.com/janeczku/calibre-web), [Calibre-Web Automated](https://github.com/crocodilestick/Calibre-Web-Automated), [Calibre-Web NextGen](https://github.com/new-usemame/Calibre-Web-NextGen) and other servers implementing the Kobo Sync protocol.

Kobo's sync protocol is normally only spoken by Kobo's stock firmware. This plugin brings it to KOReader on any device (Kobo, Kindle, Android, PocketBook, desktop).

## Features

- **Library sync** — new, changed and removed books are mirrored from the server
  - *Keep every book on this device*: every book the catalog lists is downloaded, and new ones follow as they arrive — on a first sync that is the whole library
  - *On demand* (for large libraries): sync only updates the catalog; browse the server library on-device — grouped by series, chapters in reading order, optionally as a cover grid — and download books as you open them
- **Unattended syncs** — optionally refresh the catalog every 15, 30 or 60 minutes; runs only while Wi-Fi is already on, never starts downloads, and holds any deletions it finds until a sync you start yourself
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
3. Optionally choose the download folder and whether to *Keep every book on this device* (off means on-demand)
4. Tap *Synchronize now*

## Notes & limitations

- Reading positions are exchanged as **percentages** (the Kobo protocol's kepub spans cannot be mapped to KOReader positions). The kepub location from other Kobo devices is preserved untouched.
- Tags/shelves, annotations and highlights are not synced (v1).
- The first sync of a large library can take a while; you will be asked before bulk downloads start.
- *Reset sync* (in the menu) forgets the catalog and sync token but keeps downloaded files.

## Localization

The UI follows KOReader's language setting. Bundled: Arabic, Dutch, French, German, Italian, Japanese, Korean, Polish, Brazilian Portuguese, Russian, Simplified and Traditional Chinese, Spanish, Thai and Vietnamese; anything else falls back to English.

**These are machine translations and have not been reviewed by native speakers** — corrections are welcome. Tables live in `l10n/<code>.lua` as plain Lua maps from the English source string, and `<code>` must match KOReader's own locale code (several carry a region, such as `it_IT`, `nl_NL`, `ko_KR`). `spec/l10n_spec.lua` checks that every table covers the template exactly and preserves each placeholder, since a key that drifts silently falls back to English.

To add a language, copy `l10n/template.lua` to `l10n/<code>.lua` and translate the values.

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
