#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$project_root"

if [ -f .release.env ]; then
  set -a
  . ./.release.env
  set +a
fi

failed=0
release_profile=/Users/lim-eunkyu/.codex/profiles/app-release.json
if [ ! -f "$release_profile" ]; then
  echo "private release profile is unavailable" >&2
  failed=1
elif ! ruby -rjson -e 'p=JSON.parse(File.read(ARGV.fetch(0))); ts=p.fetch("appleTeams"); exit 1 unless ts.length == 1; t=ts.fetch(0); k=t.fetch("keyId"); exit(t.fetch("privateKeyPaths").any? { |x| File.file?(x) && File.basename(x).include?(k) } ? 0 : 1)' "$release_profile"; then
  echo "target App Store Connect key is unavailable" >&2
  failed=1
fi

expected_bundle=com.limeunkyu.lastbeacon
expected_team=BYSD998XY3
expected_app_id=6792522098
expected_admob_app=ca-app-pub-5754584472729127~8554677780
expected_interstitial=ca-app-pub-5754584472729127/3302351102
expected_rewarded=ca-app-pub-5754584472729127/7070325868
configured_bundle=$(xcodebuild -project LastBeacon.xcodeproj -target LastBeacon -configuration Release -showBuildSettings 2>/dev/null | awk '/^[[:space:]]*PRODUCT_BUNDLE_IDENTIFIER =/ { print $3; exit }')
configured_team=$(xcodebuild -project LastBeacon.xcodeproj -target LastBeacon -configuration Release -showBuildSettings 2>/dev/null | awk '/^[[:space:]]*DEVELOPMENT_TEAM =/ { print $3; exit }')
configured_admob_app=$(xcodebuild -project LastBeacon.xcodeproj -target LastBeacon -configuration Release -showBuildSettings 2>/dev/null | awk '/^[[:space:]]*GAD_APPLICATION_IDENTIFIER =/ { print $3; exit }')
configured_device_family=$(xcodebuild -project LastBeacon.xcodeproj -target LastBeacon -configuration Release -showBuildSettings 2>/dev/null | awk -F ' = ' '/^[[:space:]]*TARGETED_DEVICE_FAMILY =/ { print $2; exit }')
if [ "$configured_bundle" != "$expected_bundle" ]; then
  echo "release bundle mismatch: $configured_bundle" >&2
  failed=1
fi
if [ "$configured_team" != "$expected_team" ]; then
  echo "release team mismatch" >&2
  failed=1
fi
if [ "$configured_admob_app" != "$expected_admob_app" ]; then
  echo "AdMob app identity mismatch" >&2
  failed=1
fi
if [ "$configured_device_family" != "1" ] || [ "$(plutil -extract UIRequiresFullScreen raw LastBeacon/Resources/Info.plist 2>/dev/null || true)" != true ]; then
  echo "release must be iPhone-only and require full screen" >&2
  failed=1
fi

plist_interstitial=$(plutil -extract ProductionInterstitialID raw LastBeacon/Resources/AdConfiguration.plist 2>/dev/null || true)
plist_rewarded=$(plutil -extract ProductionRewardedID raw LastBeacon/Resources/AdConfiguration.plist 2>/dev/null || true)
if [ "$plist_interstitial" != "$expected_interstitial" ] || [ "$plist_rewarded" != "$expected_rewarded" ]; then
  echo "AdMob release configuration does not match target evidence" >&2
  failed=1
fi

if printf '%s\n%s\n%s\n' "$configured_admob_app" "$plist_interstitial" "$plist_rewarded" | grep -q '3940256099942544'; then
  echo "Google test advertising identity found in production configuration" >&2
  failed=1
fi

if ! ruby -rjson -rspaceship -e '
  p=JSON.parse(File.read(ARGV.fetch(0))); ts=p.fetch("appleTeams"); exit 1 unless ts.length == 1; t=ts.fetch(0); k=t.fetch("keyId"); path=t.fetch("privateKeyPaths").find { |x| File.file?(x) && File.basename(x).include?(k) };
  Spaceship::ConnectAPI.token=Spaceship::ConnectAPI::Token.create(key_id:k, issuer_id:t.fetch("issuerId"), filepath:path);
  a=Spaceship::ConnectAPI::App.find("com.limeunkyu.lastbeacon"); exit(a && a.id == "6792522098" ? 0 : 1)
' "$release_profile"; then
  echo "App Store Connect app identity mismatch: $expected_app_id" >&2
  failed=1
fi

for url in \
  https://leejeongeun999-hub.github.io/last-beacon/support.html \
  https://leejeongeun999-hub.github.io/last-beacon/privacy.html; do
  if ! curl --fail --silent --show-error --location --max-time 15 "$url" >/dev/null; then
    echo "required public URL is unavailable: $url" >&2
    failed=1
  fi
done

if [ "$failed" -ne 0 ]; then
  exit 1
fi

echo "release preflight passed for $expected_bundle version 1.0.0 build 1"
