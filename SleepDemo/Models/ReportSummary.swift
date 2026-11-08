import Foundation

/// 결과 화면에 그릴 값만 모은 모델. 저장된 기록(SleepRecord)을 화면용 문자열로 바꾼다.
struct ReportSummary {
    var rows: [(title: String, value: String)]
    var emptyReason: String?
    var stages: [Int]

    init(record r: SleepRecord) {
        func pct(_ v: Float?) -> String { v.map { String(format: "%.0f%%", $0 * 100) } ?? "-" }
        // SDK의 시간 값은 초 단위로 가정한다.
        func min(_ v: Int?) -> String { v.map { "\($0 / 60)분" } ?? "-" }
        let time = { (d: Date?) in d?.formatted(date: .abbreviated, time: .shortened) ?? "-" }
        rows = [
            ("측정 시작", time(r.startedAt)),
            ("측정 종료", time(r.endedAt)),
            ("API 환경", r.environment ?? "-"),
            ("누락 데이터 비율", pct(r.missingDataRatio)),
        ]
        if r.hasStat {
            rows += [
                ("수면 효율", pct(r.sleepEfficiency)),
                ("총 수면 시간", min(r.timeInSleep)),
                ("깸", min(r.timeInWake)),
                ("얕은 수면", min(r.timeInLight)),
                ("깊은 수면", min(r.timeInDeep)),
                ("REM", min(r.timeInRem)),
                ("코골이 횟수", r.snoringCount.map(String.init) ?? "-"),
                ("코골이 비율", pct(r.snoringRatio)),
            ]
        } else {
            emptyReason = "통계가 없습니다. (\(r.peculiarities.joined(separator: ", ")))"
        }
        stages = r.sleepStages
    }
}
