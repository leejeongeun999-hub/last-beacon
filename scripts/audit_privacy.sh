#!/bin/sh
set -eu

app_path=${1:-}
if [ -z "$app_path" ] || [ ! -d "$app_path" ]; then
  echo "usage: scripts/audit_privacy.sh /path/to/LastBeacon.app" >&2
  exit 2
fi

executable="$app_path/LastBeacon"
if [ ! -f "$executable" ]; then
  echo "missing app executable: $executable" >&2
  exit 3
fi

echo "Privacy manifests"
find "$app_path" -name PrivacyInfo.xcprivacy -type f -print | LC_ALL=C sort

manifest_count=$(find "$app_path" -name PrivacyInfo.xcprivacy -type f | wc -l | tr -d ' ')
if [ "$manifest_count" -lt 1 ]; then
  echo "no privacy manifest embedded" >&2
  exit 4
fi

mach_o_list=$(mktemp "${TMPDIR:-/tmp}/last-beacon-mach-o.XXXXXX")
trap 'rm -f "$mach_o_list"' EXIT INT TERM
find "$app_path" -type f -print | while IFS= read -r candidate; do
  if file "$candidate" | grep -q 'Mach-O'; then
    printf '%s\n' "$candidate"
  fi
done > "$mach_o_list"

if [ ! -s "$mach_o_list" ]; then
  echo "no Mach-O binaries found" >&2
  exit 5
fi

echo "Privacy-sensitive linked frameworks"
while IFS= read -r binary; do
  otool -L "$binary" 2>/dev/null || true
done < "$mach_o_list" | awk '/AdSupport|AppTrackingTransparency|GameKit|GoogleMobileAds|UserMessagingPlatform/ { print $1 }' | LC_ALL=C sort -u

if while IFS= read -r binary; do strings "$binary" 2>/dev/null; done < "$mach_o_list" | grep -q 'ATTrackingManager'; then
  echo "ATT symbol present"
else
  echo "ATT symbol absent"
fi
