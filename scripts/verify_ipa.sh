#!/bin/sh
set -eu

ipa=${1:-}
if [ -z "$ipa" ] || [ ! -f "$ipa" ]; then
  echo "usage: scripts/verify_ipa.sh /path/to/LastBeacon.ipa" >&2
  exit 2
fi

expected_bundle=com.limeunkyu.lastbeacon
expected_version=1.0.0
expected_build=1
expected_team=BYSD998XY3
expected_admob_app=ca-app-pub-5754584472729127~8554677780
expected_interstitial=ca-app-pub-5754584472729127/3302351102
expected_rewarded=ca-app-pub-5754584472729127/7070325868

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

[ "$bundle" = "$expected_bundle" ] || { echo "bundle mismatch" >&2; exit 4; }
[ "$version" = "$expected_version" ] || { echo "version mismatch" >&2; exit 5; }
[ "$build" = "$expected_build" ] || { echo "build mismatch" >&2; exit 6; }
[ "$encryption" = false ] || { echo "export compliance mismatch" >&2; exit 7; }
[ "$admob" = "$expected_admob_app" ] || { echo "AdMob app identity mismatch" >&2; exit 8; }

ad_config="$app/AdConfiguration.plist"
[ -f "$ad_config" ] || { echo "AdMob unit configuration missing" >&2; exit 9; }
interstitial=$(plutil -extract ProductionInterstitialID raw "$ad_config")
rewarded=$(plutil -extract ProductionRewardedID raw "$ad_config")
[ "$interstitial" = "$expected_interstitial" ] || { echo "interstitial identity mismatch" >&2; exit 10; }
[ "$rewarded" = "$expected_rewarded" ] || { echo "rewarded identity mismatch" >&2; exit 11; }

if rg -a -q 'ca-app-pub-3940256099942544' "$app"; then
  echo "test advertising identity embedded in IPA" >&2
  exit 12
fi

codesign --verify --deep --strict "$app"
codesign -d --entitlements "$temporary_directory/entitlements.plist" "$app" 2>/dev/null
game_center=$(plutil -extract com.apple.developer.game-center raw "$temporary_directory/entitlements.plist" 2>/dev/null || true)
[ "$game_center" = true ] || { echo "Game Center entitlement missing" >&2; exit 13; }
signed_application_identifier=$(plutil -extract application-identifier raw "$temporary_directory/entitlements.plist" 2>/dev/null || true)
signed_team=$(plutil -extract com.apple.developer.team-identifier raw "$temporary_directory/entitlements.plist" 2>/dev/null || true)
[ "$signed_application_identifier" = "$expected_team.$expected_bundle" ] || { echo "signed application identifier mismatch" >&2; exit 14; }
[ "$signed_team" = "$expected_team" ] || { echo "signed team mismatch" >&2; exit 15; }

if [ ! -f "$app/embedded.mobileprovision" ]; then
  echo "embedded provisioning profile missing" >&2
  exit 16
fi
security cms -D -i "$app/embedded.mobileprovision" > "$temporary_directory/profile.plist"
application_identifier=$(plutil -extract Entitlements.application-identifier raw "$temporary_directory/profile.plist")
profile_team=$(plutil -extract TeamIdentifier.0 raw "$temporary_directory/profile.plist" 2>/dev/null || true)
profile_get_task_allow=$(plutil -extract Entitlements.get-task-allow raw "$temporary_directory/profile.plist" 2>/dev/null || true)
[ "$application_identifier" = "$expected_team.$expected_bundle" ] || { echo "provisioning application identifier mismatch" >&2; exit 17; }
[ "$profile_team" = "$expected_team" ] || { echo "provisioning team mismatch" >&2; exit 18; }
[ "$profile_get_task_allow" = false ] || { echo "provisioning profile is not distribution-safe" >&2; exit 19; }
if plutil -extract ProvisionedDevices xml1 -o - "$temporary_directory/profile.plist" >/dev/null 2>&1 || \
   [ "$(plutil -extract ProvisionsAllDevices raw "$temporary_directory/profile.plist" 2>/dev/null || true)" = true ]; then
  echo "development or enterprise provisioning profile embedded" >&2
  exit 20
fi

expiration=$(plutil -extract ExpirationDate raw "$temporary_directory/profile.plist")
if ! ruby -rtime -e 'exit(Time.parse(ARGV.fetch(0)) > Time.now ? 0 : 1)' "$expiration"; then
  echo "provisioning profile is expired or unreadable" >&2
  exit 21
fi

find "$app" -name PrivacyInfo.xcprivacy -type f | grep -q . || {
  echo "privacy manifests missing" >&2
  exit 22
}

if plutil -extract NSUserTrackingUsageDescription raw "$info" >/dev/null 2>&1; then
  echo "unexpected tracking usage description embedded" >&2
  exit 23
fi

"$(dirname "$0")/audit_privacy.sh" "$app"

echo "verified signed IPA: $expected_bundle $expected_version ($expected_build), team $expected_team"
