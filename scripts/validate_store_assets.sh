#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
screenshot_root=${1:-"$project_root/fastlane/screenshots"}
expected_locales="en-US ko zh-Hans ja es-ES fr-FR pt-BR"
metadata_root="$project_root/fastlane/metadata"
hash_file="$project_root/build/store-screenshot-hashes.txt"
mkdir -p "$project_root/build"
: > "$hash_file"

for locale in $expected_locales; do
  directory="$screenshot_root/$locale"
  if [ ! -d "$directory" ]; then
    echo "missing screenshot locale: $locale" >&2
    exit 10
  fi
  count=$(find "$directory" -maxdepth 1 -type f -name '*.png' | wc -l | tr -d ' ')
  if [ "$count" -ne 3 ]; then
    echo "$locale has $count screenshots, expected 3" >&2
    exit 11
  fi
  for image in "$directory"/*.png; do
    width=$(sips -g pixelWidth "$image" | awk '/pixelWidth/ { print $2 }')
    height=$(sips -g pixelHeight "$image" | awk '/pixelHeight/ { print $2 }')
    alpha=$(sips -g hasAlpha "$image" | awk '/hasAlpha/ { print $2 }')
    byte_count=$(wc -c < "$image" | tr -d ' ')
    case "${width}x${height}" in
      1260x2736|1290x2796|1320x2868) ;;
      *)
        echo "invalid screenshot dimensions: $image ($width x $height)" >&2
        exit 12
        ;;
    esac
    if [ "$alpha" != no ]; then
      echo "screenshot has alpha: $image" >&2
      exit 13
    fi
    if [ "$byte_count" -lt 100000 ]; then
      echo "screenshot appears blank or incomplete: $image" >&2
      exit 20
    fi
    file "$image" | grep -q 'PNG image data' || {
      echo "screenshot is not PNG: $image" >&2
      exit 14
    }
    shasum -a 256 "$image" | awk '{ print $1 }' >> "$hash_file"
  done

  metadata_directory="$metadata_root/$locale"
  for filename in name.txt subtitle.txt promotional_text.txt description.txt keywords.txt support_url.txt privacy_url.txt; do
    metadata_file="$metadata_directory/$filename"
    if [ ! -s "$metadata_file" ]; then
      echo "missing metadata: $metadata_file" >&2
      exit 17
    fi
  done
  name_length=$(tr -d '\n' < "$metadata_directory/name.txt" | wc -m | tr -d ' ')
  subtitle_length=$(tr -d '\n' < "$metadata_directory/subtitle.txt" | wc -m | tr -d ' ')
  promotional_length=$(tr -d '\n' < "$metadata_directory/promotional_text.txt" | wc -m | tr -d ' ')
  keyword_bytes=$(tr -d '\n' < "$metadata_directory/keywords.txt" | wc -c | tr -d ' ')
  if [ "$name_length" -gt 30 ] || [ "$subtitle_length" -gt 30 ] || [ "$promotional_length" -gt 170 ] || [ "$keyword_bytes" -gt 100 ]; then
    echo "metadata limit exceeded for $locale" >&2
    exit 18
  fi
  grep -q '^https://' "$metadata_directory/support_url.txt" || exit 19
  grep -q '^https://' "$metadata_directory/privacy_url.txt" || exit 19
done

unique_count=$(LC_ALL=C sort -u "$hash_file" | wc -l | tr -d ' ')
if [ "$unique_count" -ne 21 ]; then
  echo "screenshot collision detected: $unique_count unique of 21" >&2
  exit 15
fi

icon="$project_root/LastBeacon/Resources/Assets.xcassets/AppIcon.appiconset/LastBeacon-AppIcon-1024.png"
icon_width=$(sips -g pixelWidth "$icon" | awk '/pixelWidth/ { print $2 }')
icon_height=$(sips -g pixelHeight "$icon" | awk '/pixelHeight/ { print $2 }')
icon_alpha=$(sips -g hasAlpha "$icon" | awk '/hasAlpha/ { print $2 }')
if [ "$icon_width" != 1024 ] || [ "$icon_height" != 1024 ] || [ "$icon_alpha" != no ]; then
  echo "invalid app icon" >&2
  exit 16
fi

echo "validated 21 screenshots, seven metadata sets, and opaque 1024px app icon"
