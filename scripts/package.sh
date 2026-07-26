#!/bin/sh
# Build dist/kobosync.koplugin.zip for release / appstore.koplugin install.
set -eu

cd "$(dirname "$0")/.."
rm -rf dist/staging dist/kobosync.koplugin.zip
mkdir -p dist/staging/kobosync.koplugin

# Ship only runtime files: lua modules at repo root plus README/LICENSE.
for f in ./*.lua README.md LICENSE; do
    [ -f "$f" ] && cp "$f" dist/staging/kobosync.koplugin/
done

# Translation tables are loaded at runtime by kobosync_gettext.lua; without
# them every string falls back to English on a translated device. The template
# is a development file and stays out.
mkdir -p dist/staging/kobosync.koplugin/l10n
for f in l10n/*.lua; do
    case "$f" in
        l10n/template.lua) continue ;;
    esac
    cp "$f" dist/staging/kobosync.koplugin/l10n/
done

(cd dist/staging && zip -qr ../kobosync.koplugin.zip kobosync.koplugin)
rm -rf dist/staging
echo "Built dist/kobosync.koplugin.zip:"
unzip -l dist/kobosync.koplugin.zip
