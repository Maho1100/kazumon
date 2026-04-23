import SwiftUI

struct PauseOverlay: View {
    let onResume: () -> Void
    let onQuit: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("pause_title")
                    .font(.zenMaru(24, weight: .black))
                    .foregroundColor(.white)

                Button(action: onResume) {
                    Text("pause_resume")
                        .font(.zenMaru(22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.green)
                        )
                }

                Button(action: onQuit) {
                    Text("pause_quit")
                        .font(.zenMaru(20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.8))
                        )
                }
            }
            .padding(.horizontal, 40)
        }
        .allowsHitTesting(true)
    }
}
