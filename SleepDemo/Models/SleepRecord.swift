import AsleepSDK
import Foundation

/// 디스크에 저장하는 측정 기록. 화면용 문자열이 아니라 SDK가 준 원본 숫자를 그대로 둔다.
/// 시간 값은 SDK 단위(초로 가정) 그대로, 비율은 0~1 그대로 저장한다.
struct SleepRecord: Codable, Identifiable {
    enum Status: String, Codable {
        case pending    // 세션만 만들어졌고 리포트는 아직 못 받음
        case completed
    }

    var id: String  // Asleep 세션 ID
    var startedAt: Date
    var endedAt: Date?
    var status: Status
    /// 사용자가 붙인 이름. 비어 있으면 측정 시각을 제목으로 쓴다.
    var title: String?
    /// 측정에 쓴 API 키 환경("test"/"live"). 이 필드가 생기기 전의 기록은 nil.
    var environment: String?

    var missingDataRatio: Float?
    var sleepEfficiency: Float?
    var timeInSleep: Int?
    var timeInWake: Int?
    var timeInLight: Int?
    var timeInDeep: Int?
    var timeInRem: Int?
    var snoringCount: Int?
    var snoringRatio: Float?
    var hasStat = false

    /// 30초 단위. -1 오류, 0 깸, 1 얕음, 2 깊음, 3 REM
    var sleepStages: [Int] = []
    var peculiarities: [String] = []

    /// 위 필드로 담지 못한 값이 있을 때를 대비한 리포트 전체 덤프.
    var rawDescription: String?

    var displayTitle: String {
        if let title, !title.isEmpty { return title }
        return startedAt.formatted(date: .abbreviated, time: .shortened)
    }

    init(pendingId: String, startedAt: Date, endedAt: Date? = nil, environment: String?) {
        id = pendingId
        self.environment = environment
        self.startedAt = startedAt
        self.endedAt = endedAt
        status = .pending
    }

    init(report: Asleep.Model.Report, startedAt: Date, endedAt: Date?, environment: String?) {
        id = report.session.id
        self.environment = environment
        self.startedAt = startedAt
        self.endedAt = endedAt
        status = .completed
        missingDataRatio = report.missingDataRatio
        if let s = report.stat {
            hasStat = true
            sleepEfficiency = s.sleepEfficiency
            timeInSleep = s.timeInSleep
            timeInWake = s.timeInWake
            timeInLight = s.timeInLight
            timeInDeep = s.timeInDeep
            timeInRem = s.timeInRem
            snoringCount = s.snoringCount
            snoringRatio = s.snoringRatio
        }
        sleepStages = report.session.sleepStages ?? []
        peculiarities = report.peculiarities.map { "\($0)" }
        rawDescription = String(describing: report)
    }
}
