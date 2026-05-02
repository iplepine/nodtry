#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
KO_METADATA_DIR="$ROOT_DIR/ios/fastlane/metadata/ko"
EN_METADATA_DIR="$ROOT_DIR/ios/fastlane/metadata/en-US"
KO_OUTPUT_FILE="$KO_METADATA_DIR/release_notes.txt"
EN_OUTPUT_FILE="$EN_METADATA_DIR/release_notes.txt"
MAX_ITEMS=7

mkdir -p "$KO_METADATA_DIR" "$EN_METADATA_DIR"

LATEST_TAG="$(git -C "$ROOT_DIR" describe --tags --abbrev=0 2>/dev/null || true)"
if [ -n "$LATEST_TAG" ]; then
  RANGE="$LATEST_TAG..HEAD"
else
  RANGE="HEAD"
fi

COMMITS=()
while IFS= read -r LINE; do
  COMMITS+=("$LINE")
done < <(
  git -C "$ROOT_DIR" log "$RANGE" --no-merges --format='%s' \
    | grep -Ev '^(chore: bump version|Merge )' \
    | head -n "$MAX_ITEMS"
)

if [ "${#COMMITS[@]}" -eq 0 ]; then
  COMMITS=("안정성 및 사용성을 개선했어요.")
fi

{
  printf "이번 버전의 변경사항\n\n"
  for COMMIT in "${COMMITS[@]}"; do
    CLEANED="${COMMIT#feat: }"
    CLEANED="${CLEANED#fix: }"
    CLEANED="${CLEANED#style: }"
    CLEANED="${CLEANED#refactor: }"
    CLEANED="${CLEANED#docs: }"
    CLEANED="${CLEANED#chore: }"
    printf -- "- %s\n" "$CLEANED"
  done
} > "$KO_OUTPUT_FILE"

{
  printf "What's New\n\n"
  printf -- "- Stability and usability improvements.\n"
} > "$EN_OUTPUT_FILE"

echo "Generated App Store release notes at $KO_OUTPUT_FILE and $EN_OUTPUT_FILE"
