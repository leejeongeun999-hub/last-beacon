#!/bin/sh
set -eu

ipa=${1:-}
if [ -z "$ipa" ] || [ ! -f "$ipa" ]; then
  echo "usage: scripts/verify_ipa.sh /path/to/LastBeacon.ipa" >&2
  exit 2
fi

temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/last-beacon-ipa.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT INT TERM
unzip -q "$ipa" -d "$temporary_directory"
app=$(find "$temporary_directory/Payload" -maxdepth 1 -type d -name '*.app' -print | head -1)
if [ -z "$app" ]; then
  echo "IPA has no application bundle" >&2
  exit 3
fi

info="$app/Info.plist"
bundle=$(plutil -extract CFBundleIdentifier raw "$info")
version=$(plutil -extract CFBundleShortVersionString raw "$info")
build=$(plutil -extract CFBundleVersion raw "$info")
admob=$(plutil -extract GADApplicationIdentifier raw "$info")
encryption=$(plutil -extract ITSAppUsesNonExemptEncryption raw "$info")

[ "$bundle" = com.limeunkyu.lastbeacon ] || { echo "bundle mismatch" >&2; exit 4; }
[ "$version" = 1.0.0 ] || { echo "version mismatch" >&2; exit 5; }
[ "$build" = 1 ] || { echo "build mismatch" >&2; exit 6; }
[ "$encryption" = false ] || { echo "export compliance mismatch" >&2; exit 7; }
[ -n "$admob" ] || { echo "missing AdMob app ID" >&2; exit 8; }

if rg -a -q 'ca-app-pub-3940256099942544' "$app"; then
  echo "test advertising identity embedded in IPA" >&2
  exit 9
fi

codesign --verify --deep --strict "$app"
codesign -d --entitlements "$temporary_directory/entitlements.plist" "$app" 2>/dev/null
game_center=$(plutil -extract com.apple.developer.game-center raw "$temporary_directory/entitlements.plist" 2>/dev/null || true)
[ "$game_center" = true ] || { echo "Game Center entitlement missing" >&2; exit 10; }

if [ ! -f "$app/embedded.mobileprovision" ]; then
  echo "embedded provisioning profile missing" >&2
  exit 11
fi
security cms -D -i "$app/embedded.mobileprovision" > "$temporary_directory/profile.plist"
application_identifier=$(plutil -extract Entitlements.application-identifier raw "$temporary_directory/profile.plist")
case "$application_identifier" in
  *.com.limeunkyu.lastbeacon) ;;
  *) echo "provisioning application identifier mismatch" >&2; exit 12 ;;
esac

find "$app" -name PrivacyInfo.xcprivacy -type f | grep -q . || {
  echo "privacy manifests missing" >&2
  exit 13
}

echo "verified signed IPA: com.limeunkyu.lastbeacon 1.0.0 (1)"
