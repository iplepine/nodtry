#!/bin/bash

# screenshots 폴더 생성
mkdir -p screenshots

# 파일명 지정 (기본값: screenshot_현재시간)
FILENAME=${1:-"screenshot_$(date +%Y%m%d_%H%M%S)"}
OUTPUT_PATH="screenshots/${FILENAME}.png"

echo "📸 3초 뒤에 현재 켜져있는 시뮬레이터의 스크린샷을 찍습니다."
echo "▶️ 시뮬레이터 화면이 잘 보이게 준비해 주세요..."

sleep 1
echo "3..."
sleep 1
echo "2..."
sleep 1
echo "1..."
sleep 1

# 스크린샷 캡쳐 실행
xcrun simctl io booted screenshot "$OUTPUT_PATH"

if [ $? -eq 0 ]; then
  echo "✅ 스크린샷 저장 완료: $OUTPUT_PATH"
else
  echo "❌ 스크린샷 저장 실패! 켜져 있고 활성화된 시뮬레이터가 있는지 확인해 주세요."
fi
