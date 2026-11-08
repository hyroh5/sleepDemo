import SwiftUI

struct StageBar: View {
    let stages: [Int]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(stages.enumerated()), id: \.offset) { _, s in
                Rectangle().fill(color(s))
            }
        }
        .frame(height: 32)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // -1 오류, 0 깸, 1 얕음, 2 깊음, 3 REM
    private func color(_ s: Int) -> Color {
        switch s {
        case 0: return .orange
        case 1: return .cyan
        case 2: return .indigo
        case 3: return .purple
        default: return .gray
        }
    }
}
