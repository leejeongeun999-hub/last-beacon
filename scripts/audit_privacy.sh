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

echo "Privacy-sensitive linked frameworks"
otool -L "$executable" | awk '/AdSupport|AppTrackingTransparency|GameKit|GoogleMobileAds|UserMessagingPlatform/ { print $1 }' | LC_ALL=C sort -u

if strings "$executable" | grep -q 'ATTrackingManager'; then
  echo "ATT symbol present"
else
  echo "ATT symbol absent"
fi
