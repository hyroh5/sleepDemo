# SleepDemo

Asleep SDK로 수면을 측정하고 결과를 바로 보여 주는 SwiftUI 데모 앱입니다. (iOS 16+)

## 실행
1. `brew install xcodegen`
2. `cp SleepDemo/Secrets.swift.example SleepDemo/Secrets.swift` 후 API 키 입력
3. `project.yml`의 `DEVELOPMENT_TEAM`과 번들 ID를 본인 것으로 변경
4. `xcodegen generate` 후 `SleepDemo.xcodeproj`를 열어 실기기에서 실행 (시뮬레이터는 마이크 입력이 제한적)

최소 5분은 측정해야 결과가 나옵니다.
