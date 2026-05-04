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
  COMMITS=()
fi

COMMITS_TEXT="$(printf '%s\n' "${COMMITS[@]}")"
KO_NOTES=()
EN_NOTES=()

add_note() {
  KO_NOTES+=("$1")
  EN_NOTES+=("$2")
}

if grep -Eq '(add plan categories|add study sprint templates)' <<< "$COMMITS_TEXT"; then
  add_note \
    "공부/운동/직접 입력 카테고리로 계획 시작이 더 빨라졌어요." \
    "Start faster with Study, Workout, and Custom categories."
fi

if grep -Eq 'direct input clear action' <<< "$COMMITS_TEXT"; then
  add_note \
    "직접 입력을 바로 지울 수 있는 삭제 버튼을 추가했어요." \
    "Added a clear button for custom input."
fi

if grep -Eq 'escalate missed commitments' <<< "$COMMITS_TEXT"; then
  add_note \
    "놓친 약속을 더 분명하게 다시 잡도록 흐름을 개선했어요." \
    "Improved follow-up for missed commitments."
fi

if grep -Eq 'sharpen study sprint product loop' <<< "$COMMITS_TEXT"; then
  add_note \
    "계획 생성부터 실행까지 핵심 루프의 안정성을 다듬었어요." \
    "Refined the core plan-to-action flow."
fi

if [ "${#KO_NOTES[@]}" -eq 0 ]; then
  add_note \
    "안정성 및 사용성을 개선했어요." \
    "Stability and usability improvements."
fi

{
  printf "이번 버전의 변경사항\n\n"
  for NOTE in "${KO_NOTES[@]}"; do
    printf -- "- %s\n" "$NOTE"
  done
} > "$KO_OUTPUT_FILE"

{
  printf "What's New\n\n"
  for NOTE in "${EN_NOTES[@]}"; do
    printf -- "- %s\n" "$NOTE"
  done
} > "$EN_OUTPUT_FILE"

echo "Generated App Store release notes at $KO_OUTPUT_FILE and $EN_OUTPUT_FILE"
