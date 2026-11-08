import SwiftUI

struct HistoryView: View {
    @ObservedObject var store: RecordStore
    let refetch: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if store.records.isEmpty {
                    Text("저장된 기록이 없습니다.").foregroundStyle(.secondary)
                } else {
                    List {
                        ForEach(store.records) { r in
                            NavigationLink {
                                RecordDetailView(store: store, recordId: r.id, refetch: refetch)
                            } label: {
                                row(r)
                            }
                        }
                        .onDelete { offsets in
                            offsets.map { store.records[$0].id }.forEach(store.delete)
                        }
                    }
                }
            }
            .navigationTitle("이전 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }

    private func row(_ r: SleepRecord) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(r.startedAt.formatted(date: .abbreviated, time: .shortened))
                if let env = r.environment {
                    Text(env.uppercased())
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill((env == "live" ? Color.green : Color.gray).opacity(0.25)))
                }
            }
            if r.status == .pending {
                Text("리포트 미수신").font(.caption).foregroundStyle(.orange)
            } else {
                Text("수면 효율 \(r.sleepEfficiency.map { String(format: "%.0f%%", $0 * 100) } ?? "-")")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

struct RecordDetailView: View {
    @ObservedObject var store: RecordStore
    let recordId: String
    let refetch: (String) -> Void

    var body: some View {
        if let r = store.record(id: recordId) {
            if r.status == .completed {
                ReportView(summary: ReportSummary(record: r))
                    .navigationTitle(r.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                VStack(spacing: 16) {
                    Text("분석 결과를 아직 받지 못했습니다.\n세션 ID: \(r.id)")
                        .multilineTextAlignment(.center)
                    Button("리포트 다시 조회") { refetch(r.id) }
                        .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        } else {
            Text("기록을 찾을 수 없습니다.")
        }
    }
}
