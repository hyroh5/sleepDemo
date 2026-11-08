import AsleepSDK
import Foundation

/// 결과 화면에 그릴 값만 모은 모델. 실제 리포트와 샘플 데이터가 같은 화면을 쓴다.
struct ReportSummary {
    var isSample = false
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

    /// 7시간 20분을 정상적으로 잤을 때를 가정한 화면 확인용 값. 실제 측정값이 아니다.
    static var sample: ReportSummary { ReportSummary() }

    private init() {
        isSample = true
        rows = [
            ("누락 데이터 비율", "0%"),
            ("수면 효율", "91%"),
            ("총 수면 시간", "6시간 40분"),
            ("깸", "20분"),
            ("얕은 수면", "3시간 30분"),
            ("깊은 수면", "1시간 30분"),
            ("REM", "1시간 40분"),
            ("코골이 횟수", "12"),
            ("코골이 비율", "6%"),
        ]
        // 30초 단위. 약 90분 주기로 얕음→깊음→얕음→REM이 반복되고 깊은 수면은 초반에 많다.
        var s: [Int] = Array(repeating: 0, count: 20)
        for cycle in 0..<5 {
            let deep = max(8, 60 - cycle * 14)
            let rem = 12 + cycle * 10
            s += Array(repeating: 1, count: 30)
            s += Array(repeating: 2, count: deep)
            s += Array(repeating: 1, count: 40)
            s += Array(repeating: 3, count: rem)
            if cycle < 4 { s += Array(repeating: 0, count: 4) }
        }
        s += Array(repeating: 0, count: 16)
        stages = s
    }
}
