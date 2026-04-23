import SwiftUI

struct HPBarView: View {
    let label: String
    let emoji: String
    let current: Int
    let max: Int
    let tint: Color

    private var progress: Double {
        guard max > 0 else { return 0 }
        return Double(current) / Double(max)
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(emoji)
                .font(.title3)

            Text(label)
                .font(.zenMaru(13, weight: .black))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.7), radius: 3, x: 0, y: 1)
                .frame(width: 80, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 6)
                        .fill(tint)
                        .frame(width: geo.size.width * progress)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 18)

            Text("\(current)/\(max)")
                .font(.zenMaru(12, weight: .black))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.7), radius: 3, x: 0, y: 1)
                .monospacedDigit()
                .frame(width: 44, alignment: .trailing)
        }
        .padding(.horizontal)
    }
}
