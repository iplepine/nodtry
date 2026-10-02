#!/bin/bash
# privacy-policy/ 와 support/ (기존 정적 페이지 정본)를 Firebase Hosting(hosting/public)으로 복사한다.
# 앱 링크: https://nod-try.web.app/{privacy,support,terms} (lib/core/legal_links.dart)
# 약관(hosting/public/terms/index.html)은 hosting 쪽이 정본이다.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p hosting/public/privacy hosting/public/support
cp privacy-policy/index.html hosting/public/privacy/index.html
sed 's#\.\./privacy-policy/#/privacy/#g' support/index.html > hosting/public/support/index.html
echo "synced privacy/support into hosting/public"
