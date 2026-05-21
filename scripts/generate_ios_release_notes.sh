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

if grep -Eq '(store assets|store screenshots|app icon|reaction icon|emoji)' <<< "$COMMITS_TEXT"; then
  add_note \
    "새 앱 아이콘과 화면 디자인에 맞춰 스토어 이미지를 갱신했어요." \
    "Updated store visuals to match the refreshed app icon and screen design."
  add_note \
    "응원과 반응 이모지가 더 깔끔하게 정렬되도록 다듬었어요." \
    "Aligned cheer and reaction emojis more cleanly."
fi

if grep -Eq '(집중 타이머|focus timer|focusTimer)' <<< "$COMMITS_TEXT"; then
  add_note \
    "약속 카드에 \"지금 할게! (집중 타이머)\" 버튼이 생겼어요. 5/10/25분 또는 직접 입력으로 즉석에서 집중 타이머를 켜고, 끝나면 노트 창이 자동으로 떠요." \
    "New \"Start Now (Focus Timer)\" button on practice cards. Pick 5/10/25 min or enter a custom duration; when the timer ends, the done-note dialog opens automatically."
fi

if grep -Eq '(똑똑 UI|poke UI|poke ui|simplify poke)' <<< "$COMMITS_TEXT"; then
  add_note \
    "똑똑 알림 UI를 더 단순하게 정리했어요. 평소 카드 그대로 사용하고, 상단에 작은 똑똑 배지만 더 보여줘요." \
    "Simplified the poke notification UI. Cards stay as usual with just a small poke badge added on top."
fi

if grep -Eq '(active promise|promise chip|보상/벌칙 chip|진행 중 약속)' <<< "$COMMITS_TEXT"; then
  add_note \
    "보상/벌칙 약속이 진행 중인 동안, 약속 카드에서 \"1번만 더 실패하면 벌칙\" 같은 경고나 \"보상까지 2일\" 같은 진척을 한 줄로 바로 볼 수 있어요. 탭하면 자세한 조건과 진행 바가 나와요." \
    "While a reward/penalty promise is active, the practice card now shows a one-line chip like \"1 more miss triggers the penalty\" or \"2 more days to the reward\". Tap for full conditions and a progress bar."
fi

if grep -Eq '(focus timer UX|집중 타이머 UX|focus timer button|focusTimer CTA|done now button)' <<< "$COMMITS_TEXT"; then
  add_note \
    "집중 타이머에 \"했어! 지금 끝낼게\" 버튼이 생겼어요. 타이머 끝까지 안 기다려도 바로 완료 처리되고, 노트에 \"X분 Y초 동안 집중해서 완료했어요!\"가 자동으로 채워져요." \
    "Focus timer now has a \"Done now\" button — finish early without waiting for the timer, and the note auto-fills with \"Focused for X min Y sec!\"."
  add_note \
    "집중 시간 선택 창이 화면 하단 시스템 바에 가리던 문제를 고쳤어요." \
    "Fixed: the focus duration picker was being clipped by the system navigation area at the bottom of the screen."
fi

if grep -Eq '(system locale|follow.*locale|follow.*system|device language|persist.*locale|locale.*persist|nullable locale)' <<< "$COMMITS_TEXT"; then
  add_note \
    "앱을 처음 실행할 때 기기 언어 설정을 따라가요. 한국어 기기는 한국어로, 영어 기기는 영어로 자동 시작합니다." \
    "The app now starts in your device's language on first launch — Korean for Korean devices, English for English devices."
  add_note \
    "설정에서 직접 바꾼 언어는 다음 실행에서도 그대로 유지돼요." \
    "Any language you pick in Settings is remembered for next time."
fi

if grep -Eq '(full English localization|English translation|i18n|localize|localization)' <<< "$COMMITS_TEXT"; then
  add_note \
    "약속 만들기, 알림, 집중 타이머 등 앱 곳곳의 텍스트를 영어로도 자연스럽게 번역했어요." \
    "Polished the English translation across plan creation, notifications, focus timer, and more."
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
