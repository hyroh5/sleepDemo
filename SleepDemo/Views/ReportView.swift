import SwiftUI

struct ReportView: View {
    let summary: ReportSummary

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if summary.isSample {
                    Text("샘플 데이터 · 실제 측정값이 아닙니다")
                        .font(.footnote.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.orange.opacity(0.25)))
                }
                ForEach(Array(summary.rows.enumerated()), id: \.offset) { _, r in
                    HStack {
                        Text(r.title)
                        Spacer()
                        Text(r.value).foregroundStyle(.secondary)
                    }
                }
                if let reason = summary.emptyReason {
                    Text(reason)
                }
                if !summary.stages.isEmpty {
                    Text("수면 단계").font(.headline).padding(.top)
                    StageBar(stages: summary.stages)
                    HStack(spacing: 12) {
                        legend("깸", .orange)
                        legend("얕음", .cyan)
                        legend("깊음", .indigo)
                        legend("REM", .purple)
                    }
                    .font(.caption)
                }
            }
            .padding()
        }
    }

    private func legend(_ title: String, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(title)
        }
    }
}
