# hangang-temp-cli

한강 수온을 CLI에서 즉시 조회하는 도구입니다.  
서울시 공공데이터 `WPOSInformationTime` API를 사용합니다.

## 요구 사항

- Node.js ≥ 18 (내장 `fetch` 사용)
- npm ≥ 8
- 서울시 열린데이터광장 API 키 ([link](https://data.seoul.go.kr/together/mypage/actkeyMng_ss.do#))

## 설치

```bash
git clone https://github.com/HaeeunJeong/hangang-temp.git ~/.local/hangang-temp
cd ~/.local/hangang-temp

chmod +x ./install.sh
./install.sh
```
