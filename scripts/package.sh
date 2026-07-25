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

(cd dist/staging && zip -qr ../kobosync.koplugin.zip kobosync.koplugin)
rm -rf dist/staging
echo "Built dist/kobosync.koplugin.zip:"
unzip -l dist/kobosync.koplugin.zip
