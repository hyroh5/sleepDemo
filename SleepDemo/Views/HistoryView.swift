import SwiftUI

struct HistoryView: View {
    @ObservedObject var store: RecordStore
    let refetch: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var renamingId: String?
    @State private var draft = ""

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
                            .swipeActions(edge: .leading) {
                                Button("이름 변경") { startRename(r) }.tint(.blue)
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
            .alert("이름 변경", isPresented: Binding(
                get: { renamingId != nil },
                set: { if !$0 { renamingId = nil } }
            )) {
                TextField("이름", text: $draft)
                Button("저장") {
                    if let id = renamingId { store.rename(id: id, title: draft) }
                    renamingId = nil
                }
                Button("취소", role: .cancel) { renamingId = nil }
            } message: {
                Text("비워 두면 측정 시각이 이름으로 표시됩니다.")
            }
        }
    }

    private func startRename(_ r: SleepRecord) {
        draft = r.title ?? ""
        renamingId = r.id
    }

    private func row(_ r: SleepRecord) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(r.displayTitle)
                if let env = r.environment {
                    Text(env.uppercased())
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill((env == "live" ? Color.green : Color.gray).opacity(0.25)))
                }
            }
            if r.title?.isEmpty == false {
                Text(r.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundStyle(.secondary)
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
    @Environment(\.dismiss) private var dismiss

    @State private var showRename = false
    @State private var showDelete = false
    @State private var draft = ""

    var body: some View {
        Group {
            if let r = store.record(id: recordId) {
                if r.status == .completed {
                    ReportView(summary: ReportSummary(record: r))
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
        .navigationTitle(store.record(id: recordId)?.displayTitle ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let r = store.record(id: recordId) {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("이름 변경", systemImage: "pencil") {
                            draft = r.title ?? ""
                            showRename = true
                        }
                        Button("삭제", systemImage: "trash", role: .destructive) {
                            showDelete = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .alert("이름 변경", isPresented: $showRename) {
            TextField("이름", text: $draft)
            Button("저장") { store.rename(id: recordId, title: draft) }
            Button("취소", role: .cancel) {}
        } message: {
            Text("비워 두면 측정 시각이 이름으로 표시됩니다.")
        }
        .confirmationDialog("이 기록을 삭제할까요?", isPresented: $showDelete, titleVisibility: .visible) {
            Button("삭제", role: .destructive) {
                store.delete(id: recordId)
                dismiss()
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("삭제하면 되돌릴 수 없습니다.")
        }
    }
}
