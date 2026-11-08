import Foundation

/// Documents/sleep_records.json 한 파일에 전체 기록을 저장한다.
@MainActor
final class RecordStore: ObservableObject {
    @Published private(set) var records: [SleepRecord] = []

    private let url: URL

    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        url = dir.appendingPathComponent("sleep_records.json")
        load()
    }

    func record(id: String) -> SleepRecord? {
        records.first { $0.id == id }
    }

    func upsert(_ record: SleepRecord) {
        if let i = records.firstIndex(where: { $0.id == record.id }) {
            records[i] = record
        } else {
            records.append(record)
        }
        records.sort { $0.startedAt > $1.startedAt }
        save()
    }

    func rename(id: String, title: String) {
        guard let i = records.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        records[i].title = trimmed.isEmpty ? nil : trimmed
        save()
    }

    func delete(id: String) {
        records.removeAll { $0.id == id }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: url) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        records = (try? decoder.decode([SleepRecord].self, from: data)) ?? []
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            try encoder.encode(records).write(to: url, options: .atomic)
        } catch {
            print("기록 저장 실패: \(error)")
        }
    }
}
