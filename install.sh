#!/usr/bin/env bash
# 한강 수온 CLI 설치 스크립트
# 사용: bash install.sh

set -u

### ── 출력 도우미 ──────────────────────────────────────────────────────────────
C_RESET='\033[0m'; C_BLUE='\033[1;34m'; C_GREEN='\033[1;32m'; C_RED='\033[1;31m'; C_YELLOW='\033[1;33m'
step(){ echo -e "${C_BLUE}▶ $*${C_RESET}"; }
ok(){   echo -e "${C_GREEN}✔ $*${C_RESET}"; }
fail(){ echo -e "${C_RED}✘ $*${C_RESET}"; exit 1; }

### ── 사전 점검 ────────────────────────────────────────────────────────────────
step "사전 점검"
command -v node >/dev/null 2>&1 || fail "Node.js가 필요합니다. Node 18 이상을 설치하십시오."
command -v npm  >/dev/null 2>&1 || fail "npm이 필요합니다."
[ -f "package.json" ] || fail "package.json이 없습니다. 프로젝트 루트에서 실행하십시오."
[ -f "index.js" ] || fail "index.js가 없습니다."

PROJECT_DIR="$(pwd)"

# 패키지 이름과 bin 이름 추출
PKG_NAME="$(node -e "console.log(JSON.parse(require('fs').readFileSync('package.json','utf8')).name||'hangang-temp')" 2>/dev/null || echo hangang-temp)"
BIN_NAME="$(node -e "const fs=require('fs');const p=JSON.parse(fs.readFileSync('package.json','utf8'));if(p.bin&&typeof p.bin==='object'){console.log(Object.keys(p.bin)[0])}else if(typeof p.bin==='string'){console.log(p.name||'hangang-temp')}else{console.log('hangang-temp')}" 2>/dev/null || echo hangang-temp)"

ok "패키지: ${PKG_NAME}, 실행명령: ${BIN_NAME}"

### ── 1) 의존성 설치 ──────────────────────────────────────────────────────────
step "npm install (의존성 설치)"
npm install && ok "의존성 설치 완료" || fail "npm install 실패"

### ── 2) SEOUL_API 입력 및 .env 작성 ─────────────────────────────────────────
step "SEOUL_API 입력"
read -r -p "발급받은 서울시 API 키를 입력하십시오: " SEOUL_API
[ -n "${SEOUL_API}" ] || fail "SEOUL_API가 비어 있습니다."
echo "SEOUL_API=${SEOUL_API}" > "${PROJECT_DIR}/.env" || fail ".env 작성 실패"
ok ".env 작성 완료 → ${PROJECT_DIR}/.env"

### ── 3) 로컬 실행 검증 ───────────────────────────────────────────────────────
step "node index.js 실행 검증"
if node index.js >/tmp/hangang_test.out 2>/tmp/hangang_test.err; then
  ok "로컬 실행 성공"
  tail -n +1 /tmp/hangang_test.out | sed -e 's/^/  /'
else
  cat /tmp/hangang_test.err 1>&2
  fail "로컬 실행 실패"
fi

### ── 4) 실행 권한 부여 ───────────────────────────────────────────────────────
step "index.js 실행 권한 부여"
chmod +x index.js && ok "chmod +x index.js 적용" || fail "chmod 실패"

### ── 5) 전역 링크 생성 (sudo 필요) ───────────────────────────────────────────
step "전역 링크 생성: sudo npm link"
if sudo npm link; then
  ok "전역 링크 생성 완료"
else
  fail "sudo npm link 실패"
fi

### ── 6) 전역 설치물 권한 정리 ────────────────────────────────────────────────
MODULE_DIRS=(
  "/usr/lib/node_modules/${PKG_NAME}"
  "/usr/local/lib/node_modules/${PKG_NAME}"
)
BIN_CANDS=(
  "/usr/bin/${BIN_NAME}"
  "/usr/local/bin/${BIN_NAME}"
)

step "전역 설치물 권한 정리"
FOUND_MODULE=0
for d in "${MODULE_DIRS[@]}"; do
  if [ -d "$d" ]; then
    sudo chmod -R a+rx "$d" || fail "권한 수정 실패: $d"
    ok "모듈 권한 수정: $d"
    FOUND_MODULE=1
  fi
done
[ "$FOUND_MODULE" -eq 1 ] || step "모듈 디렉터리를 발견하지 못했습니다. 배포 경로가 배포판에 따라 다를 수 있습니다."

FOUND_BIN=0
for b in "${BIN_CANDS[@]}"; do
  if [ -e "$b" ]; then
    sudo chmod a+rx "$b" || fail "권한 수정 실패: $b"
    ok "실행파일 권한 수정: $b"
    FOUND_BIN=1
  fi
done
[ "$FOUND_BIN" -eq 1 ] || step "실행파일을 발견하지 못했습니다. PATH에 생성된 다른 경로를 확인하십시오."

### ── 7) 시스템용 .env 연결 (/etc/hangang/.env) ──────────────────────────────
step "시스템 .env 연결(/etc/hangang/.env)"
sudo mkdir -p /etc/hangang || fail "/etc/hangang 생성 실패"
sudo ln -sf "${PROJECT_DIR}/.env" /etc/hangang/.env || fail "심볼릭 링크 생성 실패(/etc/hangang/.env)"
sudo chmod 755 /etc/hangang || fail "디렉터리 권한 설정 실패"
sudo chmod 644 /etc/hangang/.env || fail "파일 권한 설정 실패"
ok "/etc/hangang/.env 연결 및 권한 설정 완료"

### ── 8) 전역 명령 실행 검증 ─────────────────────────────────────────────────
step "전역 명령 실행 검증: ${BIN_NAME}"
BIN_PATH="$(command -v "${BIN_NAME}" || true)"
if [ -n "${BIN_PATH}" ]; then
  ok "실행 경로: ${BIN_PATH}"
else
  step "PATH에서 ${BIN_NAME}를 찾지 못했습니다. 셸 재시작이 필요할 수 있습니다."
fi

if "${BIN_NAME}" >/tmp/hangang_global.out 2>/tmp/hangang_global.err; then
  ok "전역 실행 성공"
  tail -n +1 /tmp/hangang_global.out | sed -e 's/^/  /'
else
  cat /tmp/hangang_global.err 1>&2
  fail "전역 실행 실패"
fi

ok "설치 완료"

