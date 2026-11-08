# SleepDemo

Asleep SDK로 수면을 측정하고, 결과를 기기에 저장해 다시 볼 수 있는 SwiftUI 데모 앱입니다. (iOS 16+)
데이터분석 캡스톤디자인에서 수면 데이터를 모으는 용도입니다.

## 기능
- 수면 측정 (마이크 사용, 최소 5분), 측정 중 화면 켜 두기와 검은 화면
- 측정 결과: 수면 효율, 수면 단계별 시간, 코골이, 누락 데이터 비율, 수면 단계 그래프
- **이전 기록**: 모든 측정을 기기에 저장하고 목록에서 다시 조회, 삭제
- 리포트를 못 받은 기록은 "리포트 미수신"으로 남고, 기록 화면에서 **다시 조회** 가능
- 앱 안에서 API 키 입력(Keychain 저장)과 환경(test/live) 선택, 기록에 환경 표시

## 저장되는 데이터
기록은 앱의 Documents 폴더에 `sleep_records.json` 한 파일로 저장됩니다. 숫자는 SDK 원본 값 그대로입니다.

| 필드 | 설명 |
|---|---|
| `id` | Asleep 세션 ID |
| `startedAt`, `endedAt` | 측정 시작/종료 시각 (ISO 8601) |
| `status` | `pending`(리포트 미수신) / `completed` |
| `environment` | 측정에 쓴 키 환경 (`test`/`live`) |
| `missingDataRatio`, `sleepEfficiency`, `snoringRatio` | 비율 (0~1) |
| `timeInSleep`, `timeInWake`, `timeInLight`, `timeInDeep`, `timeInRem` | 시간 (SDK 단위, 초로 가정) |
| `snoringCount` | 코골이 횟수 |
| `sleepStages` | 30초 단위 수면 단계 (-1 오류, 0 깸, 1 얕음, 2 깊음, 3 REM) |
| `peculiarities` | 통계가 없을 때의 사유 |
| `rawDescription` | 리포트 전체 덤프 (위 필드에 없는 값 확인용) |

파일 앱(iPhone) 또는 Finder/iTunes 파일 공유(Mac)에서 `SleepDemo` 폴더의 JSON을 꺼내 분석에 쓸 수 있습니다.
앱을 지우면 기록도 함께 삭제되니 중요한 데이터는 주기적으로 꺼내 두세요.

## 폴더 구조
```
SleepDemo/
├─ App/          앱 진입점
├─ Models/       SleepRecord(저장 모델), ReportSummary(화면용 값)
├─ Services/     RecordStore(JSON 저장), SettingsStore, KeychainStore
├─ ViewModels/   SleepViewModel(측정 상태 머신)
└─ Views/        ContentView, HistoryView, ReportView, StageBar, SettingsView
```

## 설치
### 1. Mac이 있을 때
1. `brew install xcodegen`
2. `project.yml`의 `DEVELOPMENT_TEAM`과 번들 ID를 본인 것으로 변경
3. `xcodegen generate` 후 `SleepDemo.xcodeproj`를 열어 실기기에서 실행 (시뮬레이터는 마이크 입력이 제한적)

### 2. Mac이 없을 때 (Windows)
GitHub Actions로 서명 없는 `.ipa`를 만들고, Sideloadly로 설치합니다.

1. 저장소의 **Actions** 탭 > **Build IPA** > **Run workflow** (5~10분)
2. 실행 결과 페이지 아래 **Artifacts**에서 `SleepDemo-ipa`를 받아 압축을 풉니다.
3. [sideloadly.io](https://sideloadly.io)에서 Sideloadly를 받아 설치합니다. 공식 사이트에서만 받으세요.
4. iPhone을 USB로 연결하고 "이 컴퓨터를 신뢰"를 누릅니다.
5. Sideloadly에 `.ipa`를 끌어다 놓고 Apple ID로 설치합니다.
6. iPhone 설정 > 개인정보 보호 및 보안 > **개발자 모드**를 켜고 재부팅합니다.
7. 설정 > 일반 > VPN 및 기기 관리에서 해당 Apple ID를 신뢰합니다.

주의:
- **Apple ID는 이 용도로 만든 서브 계정을 권장합니다.** 결제수단과 iCloud가 묶이지 않은 계정이고, 2단계 인증을 켜 두세요. iPhone에는 로그인하지 않고 Sideloadly에만 입력합니다.
- 무료 Apple ID로 서명한 앱은 **7일 후 만료**됩니다. 같은 계정으로 같은 `.ipa`를 다시 설치하면 되고, 덮어 설치하면 기록은 유지됩니다. 앱을 지우거나 다른 계정으로 설치하면 기록이 사라집니다.
- `.ipa`에는 API 키가 들어 있지 않아서, 저장소가 공개여도 키가 노출되지 않습니다.

## API 키
앱을 처음 실행하면 API 키 입력 화면이 나옵니다. 키는 기기의 Keychain에만 저장됩니다.
키는 [Asleep 대시보드](https://dashboard.asleep.ai)의 Settings > API Key에서 발급합니다.

- **test**: 개발용 키. 문서상 Trial 플랜(최대 60일, 유효 세션 500회까지 무료)에서는 test 키만 사용합니다.
- **live**: 실서비스용 키. 별도 계약과 과금 대상입니다.
- test와 live는 사용자·세션 데이터가 따로 관리됩니다. 설정에서 키와 같은 환경을 골라야 합니다.

## 측정 방법
1. 폰을 베개 옆 가까이에 두고 충전기에 꽂습니다.
2. **측정 시작**을 누르고, 잠금 버튼으로 화면을 끄지 않습니다. (화면이 잠기면 업로드가 끊깁니다.) 필요하면 **화면 어둡게**를 누르고, 화면을 탭하면 돌아옵니다.
3. 아침에 **측정 종료**를 누르면 분석 후 결과가 나오고 자동으로 저장됩니다.
4. 최소 5분은 측정해야 결과가 나옵니다.
