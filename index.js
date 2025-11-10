#!/usr/bin/env node
// ES Module + Node 18+ 내장 fetch
import "dotenv/config";

function fmtDate(yMd, hr) {
  const y = String(yMd).slice(0, 4);
  const m = String(yMd).slice(4, 6);
  const d = String(yMd).slice(6, 8);
  return `${y}-${m}-${d} ${hr}`;
}

function sortKey(yMd, hr) {
  const hhmm = String(hr || "")
    .replace(":", "")
    .padStart(4, "0");
  return `${yMd}${hhmm}`;
}

async function main() {
  try {
    const apiKey = process.env.SEOUL_API;
    if (!apiKey) {
      console.error("환경변수 SEOUL_API가 설정되지 않았습니다 (.env 확인).");
      process.exit(1);
    }

    const url = `http://openapi.seoul.go.kr:8088/${apiKey}/json/WPOSInformationTime/1/50/`;
    const res = await fetch(url);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const body = await res.json();

    const rows = body?.WPOSInformationTime?.row;
    if (!Array.isArray(rows) || rows.length === 0) {
      console.error("API 응답 오류: 데이터 없음");
      process.exit(1);
    }

    const stationFilter = process.argv[2]?.trim();

    let data = rows.filter(
      (r) =>
        r && r.WATT != null && r.WATT !== "" && !Number.isNaN(Number(r.WATT)),
    );

    if (stationFilter) {
      data = data.filter((r) =>
        String(r.MSRSTN_NM || "").includes(stationFilter),
      );
      if (data.length === 0) {
        console.log(`측정소 '${stationFilter}' 데이터가 없습니다.`);
        process.exit(0);
      }
    }

    data.sort((a, b) =>
      sortKey(b.YMD, b.HR).localeCompare(sortKey(a.YMD, a.HR)),
    );

    const r = data[0];
    console.log(`📍 측정소: ${r.MSRSTN_NM}`);
    console.log(`🌡️  수온: ${Number(r.WATT)} °C`);
    console.log(`🕒 시간: ${fmtDate(r.YMD, r.HR)}`);
  } catch (e) {
    console.error("오류:", e.message);
    process.exit(1);
  }
}

main();
