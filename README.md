# hangang-temp-cli

한강 수온을 CLI에서 즉시 조회하는 도구입니다.  
서울시 공공데이터 `WPOSInformationTime` API를 사용합니다.

## 요구 사항

- Node.js ≥ 18 (내장 `fetch` 사용)
- npm ≥ 8
- 서울시 열린데이터광장 API 키 ([link](https://data.seoul.go.kr/together/mypage/actkeyMng_ss.do#))

## 설치

### 1) 저장소 클론
```bash
git clone <YOUR_REPO_URL> hangang-temp
cd hangang-temp
```


### 2) 의존성 설치
```bash
npm install
```

### 3) 환경 변수 설정

프로젝트 루트에 .env 파일을 생성합니다.
```bash
echo "SEOUL_API=발급받은_서울시_API_키" > .env
```


### 4) 실행
```bash
node index.js           
```

### 전역 명령어로 사용

개발 중 전역 링크:

```bash
chmod +x index.js
sudo npm link
hangang-temp
```


패키지로 설치(배포 후):

```bash
npm install -g hangang-temp
hangang-temp
```

전역 명령 이름은 package.json의 bin에 설정된 "hangang": "./index.js"를 따릅니다.

### 출력 예시
```bash
측정소: 선유
수온: 14.6 °C
시간: 2025-11-10 14:00
```
