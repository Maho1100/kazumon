import SwiftUI

struct RankBadgePopupView: View {
    let floor: Int
    let correctCount: Int
    let totalCount: Int
    let bestFloor: Int
    let isNewRecord: Bool
    let onDismiss: () -> Void

    @State private var opacity: Double = 0
    @State private var scale: Double = 0.8

    private var stars: Int {
        FloorRank.stars(correctCount: correctCount, totalCount: totalCount)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 20) {
                Text(FloorRank.medal(for: floor))
                    .font(.system(size: 72))

                Text(String(format: NSLocalizedString("rank_floor_reached", comment: ""), floor))
                    .font(.zenMaru(20, weight: .bold))
                    .foregroundColor(.black)

                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { i in
                        Text(i <= stars ? "⭐" : "☆")
                            .font(.system(size: 32))
                    }
                }

                Text(FloorRank.starMessage(for: stars))
                    .font(.zenMaru(18, weight: .bold))
                    .foregroundColor(.orange)

                if isNewRecord {
                    Text("rank_new_record")
                        .font(.zenMaru(15, weight: .bold))
                        .foregroundColor(.red)
                } else {
                    Text(String(format: NSLocalizedString("rank_best_floor", comment: ""), FloorRank.medal(for: bestFloor), bestFloor))
                        .font(.zenMaru(14))
                        .foregroundColor(.gray)
                }

                Button {
                    dismiss()
                } label: {
                    Text("rank_next")
                        .font(.zenMaru(18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.orange)
                        )
                }
                .padding(.top, 4)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.2),
                            radius: 12, x: 0, y: 4)
            )
            .padding(.horizontal, 24)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(duration: 0.4)) {
                    opacity = 1
                    scale = 1
                }
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            opacity = 0
            scale = 0.8
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}
