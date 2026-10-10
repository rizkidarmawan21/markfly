#!/bin/sh

set -eu

RELEASE_BASE="https://github.com/rizkidarmawan21/markfly.md/releases/latest/download"
INSTALL_DIR="$HOME/Applications"
APP_NAME="Markfly.app"
DESTINATION="$INSTALL_DIR/$APP_NAME"
STAGING="$INSTALL_DIR/.Markfly.app.installing"
ROLLBACK="$INSTALL_DIR/.Markfly.app.rollback"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/markfly-install.XXXXXX")"

cleanup() {
  status=$?
  if [ "$status" -ne 0 ] && [ -d "$ROLLBACK" ] && [ ! -d "$DESTINATION" ]; then
    mv "$ROLLBACK" "$DESTINATION"
  fi
  rm -rf "$TEMP_DIR" "$STAGING"
}

fail() {
  printf 'Markfly install failed: %s\n' "$1" >&2
  exit 1
}

trap cleanup 0
trap 'exit 1' 1 2 15

[ "$(uname -s)" = "Darwin" ] || fail "macOS is required."

case "$(uname -m)" in
  arm64|aarch64) ;;
  *) fail "Apple silicon is required by the current Markfly release." ;;
esac

for command in curl awk ditto openssl; do
  command -v "$command" >/dev/null 2>&1 || fail "Missing required command: $command"
done

METADATA="$TEMP_DIR/latest-mac.yml"
ARCHIVE="$TEMP_DIR/Markfly.zip"
EXTRACTED="$TEMP_DIR/extracted"

printf 'Finding latest Markfly release...\n'
curl -fL --retry 3 --connect-timeout 15 "$RELEASE_BASE/latest-mac.yml" -o "$METADATA"

ASSET_NAME="$(awk '/^path: / { print $2; exit }' "$METADATA")"
EXPECTED_SHA512="$(awk '/^path: / { found=1; next } found && /^sha512: / { print $2; exit }' "$METADATA")"

case "$ASSET_NAME" in
  Markfly-*-arm64-mac.zip) ;;
  *) fail "Latest release metadata contains an unexpected asset name." ;;
esac

[ -n "$EXPECTED_SHA512" ] || fail "Latest release metadata has no SHA-512 digest."

printf 'Downloading %s...\n' "$ASSET_NAME"
curl -fL --retry 3 --connect-timeout 15 "$RELEASE_BASE/$ASSET_NAME" -o "$ARCHIVE"

printf 'Verifying download...\n'
ACTUAL_SHA512="$(openssl dgst -sha512 -binary "$ARCHIVE" | openssl base64 -A)"
[ "$ACTUAL_SHA512" = "$EXPECTED_SHA512" ] || fail "SHA-512 verification failed."

mkdir -p "$EXTRACTED" "$INSTALL_DIR"
ditto -x -k "$ARCHIVE" "$EXTRACTED"

SOURCE_APP="$(find "$EXTRACTED" -maxdepth 3 -type d -name "$APP_NAME" -print -quit)"
[ -n "$SOURCE_APP" ] || fail "$APP_NAME was not found in the release archive."

rm -rf "$STAGING"
if [ -d "$ROLLBACK" ] && [ ! -d "$DESTINATION" ]; then
  mv "$ROLLBACK" "$DESTINATION"
else
  rm -rf "$ROLLBACK"
fi
ditto "$SOURCE_APP" "$STAGING"

osascript -e 'tell application "Markfly" to quit' >/dev/null 2>&1 || true

if [ -d "$DESTINATION" ]; then
  mv "$DESTINATION" "$ROLLBACK"
fi

if ! mv "$STAGING" "$DESTINATION"; then
  [ -d "$ROLLBACK" ] && mv "$ROLLBACK" "$DESTINATION"
  fail "Could not move Markfly into $INSTALL_DIR."
fi

rm -rf "$ROLLBACK"

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [ -x "$LSREGISTER" ]; then
  "$LSREGISTER" -f "$DESTINATION" >/dev/null 2>&1 || true
fi

printf '\nMarkfly installed at %s\n' "$DESTINATION"
printf 'Open it with: open "%s"\n' "$DESTINATION"
