#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
if [ -n "${LAST_BEACON_SIMULATOR_ID:-}" ]; then
  simulator_id=$LAST_BEACON_SIMULATOR_ID
else
  simulator_id=$(xcrun simctl list devices available | sed -n '/LastBeacon Store iPhone 17 Pro Max/ s/.*(\([0-9A-F-][0-9A-F-]*\)).*/\1/p' | head -1)
fi
if [ -z "$simulator_id" ]; then
  echo "missing dedicated LastBeacon Store iPhone 17 Pro Max simulator" >&2
  exit 6
fi
derived_data="$project_root/build/screenshots-derived"
app_path="$derived_data/Build/Products/Debug-iphonesimulator/LastBeacon.app"
output_root="$project_root/fastlane/screenshots"
alpha_tool="$project_root/build/strip_png_alpha"

cd "$project_root"
swiftc -O scripts/strip_png_alpha.swift -o "$alpha_tool"
xcodegen generate >/dev/null
xcodebuild build -quiet \
  -project LastBeacon.xcodeproj \
  -scheme LastBeacon \
  -derivedDataPath "$derived_data" \
  -destination "platform=iOS Simulator,id=$simulator_id"

xcrun simctl bootstatus "$simulator_id" -b >/dev/null
xcrun simctl status_bar "$simulator_id" override --time 9:41 --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularBars 4 >/dev/null
xcrun simctl install "$simulator_id" "$app_path"

capture() {
  app_locale=$1
  store_locale=$2
  state=$3
  number=$4
  label=$5
  locale_directory="$output_root/$store_locale"
  raw_path="$project_root/build/screenshots-$store_locale-$state.png"
  final_path="$locale_directory/${number}_${label}.png"
  mkdir -p "$locale_directory"
  SIMCTL_CHILD_LAST_BEACON_SCREENSHOT_STATE="$state" \
    xcrun simctl launch --terminate-running-process "$simulator_id" com.limeunkyu.lastbeacon \
      -AppleLanguages "($app_locale)" \
      -AppleLocale "$app_locale" >/dev/null
  sleep 3
  xcrun simctl io "$simulator_id" screenshot --type=png "$raw_path" >/dev/null
  raw_width=$(sips -g pixelWidth "$raw_path" | awk '/pixelWidth/ { print $2 }')
  raw_height=$(sips -g pixelHeight "$raw_path" | awk '/pixelHeight/ { print $2 }')
  case "${raw_width}x${raw_height}" in
    1260x2736|1290x2796|1320x2868)
      cp "$raw_path" "$final_path"
      ;;
    *)
      sips --padToHeightWidth 2796 1290 --padColor 050816 "$raw_path" --out "$final_path" >/dev/null
      ;;
  esac
  "$alpha_tool" "$final_path" "$final_path.flattened.png"
  mv "$final_path.flattened.png" "$final_path"
}

while IFS='|' read -r app_locale store_locale; do
  [ -n "$app_locale" ] || continue
  capture "$app_locale" "$store_locale" home 1 home
  capture "$app_locale" "$store_locale" active 2 battle
  capture "$app_locale" "$store_locale" upgrade 3 upgrade
done <<'LOCALES'
en|en-US
ko|ko
zh-Hans|zh-Hans
ja|ja
es|es-ES
fr|fr-FR
pt-BR|pt-BR
LOCALES

"$project_root/scripts/validate_store_assets.sh" "$output_root"
