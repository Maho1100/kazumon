import SwiftUI

struct CertificateView: View {
    let playerName: String
    let completionDate: String
    var bestFloor: Int = 0
    var totalCorrect: Int = 0
    var totalAnswered: Int = 0
    let onDismiss: () -> Void

    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false

    var body: some View {
        ZStack {
            // ゴールドグラデーション背景
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.85, blue: 0.55),
                    Color(red: 0.85, green: 0.65, blue: 0.30)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                certificateCard

                Spacer()

                // ボタン
                VStack(spacing: 12) {
                    Button {
                        generateAndShare()
                    } label: {
                        HStack(spacing: 8) {
                            Text("📸")
                                .font(.system(size: 20))
                            Text("certificate_share")
                                .font(.zenMaru(18, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                    }

                    Button {
                        onDismiss()
                    } label: {
                        Text("certificate_close")
                            .font(.zenMaru(16, weight: .bold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
    }

    // MARK: - 修了証カード

    private var certificateCard: some View {
        VStack(spacing: 14) {
            Text("🏆")
                .font(.system(size: 56))

            Text("certificate_title")
                .font(.zenMaru(26, weight: .black))
                .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 0.1))

            Rectangle()
                .fill(LinearGradient(colors: [.clear, Color(red: 0.8, green: 0.65, blue: 0.3), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1.5)
                .padding(.horizontal, 20)

            VStack(spacing: 6) {
                Text(String(format: NSLocalizedString("certificate_player", comment: ""), playerName))
                    .font(.zenMaru(20, weight: .black))

                Text("certificate_achievement")
                    .font(.zenMaru(15, weight: .bold))
                    .foregroundStyle(.secondary)
            }

            Text("certificate_congrats")
                .font(.zenMaru(13, weight: .regular))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)

            Rectangle()
                .fill(LinearGradient(colors: [.clear, Color(red: 0.8, green: 0.65, blue: 0.3), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1.5)
                .padding(.horizontal, 20)

            if bestFloor > 0 || totalAnswered > 0 {
                HStack(spacing: 16) {
                    if bestFloor > 0 {
                        VStack(spacing: 2) {
                            Text("🏔️").font(.system(size: 18))
                            Text("F\(bestFloor)")
                                .font(.zenMaru(14, weight: .black))
                                .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 0.1))
                            Text(NSLocalizedString("certificate_best_floor", comment: ""))
                                .font(.zenMaru(9, weight: .regular))
                                .foregroundStyle(.secondary)
                        }
                    }
                    if totalAnswered > 0 {
                        VStack(spacing: 2) {
                            Text("✅").font(.system(size: 18))
                            Text("\(totalAnswered > 0 ? totalCorrect * 100 / totalAnswered : 0)%")
                                .font(.zenMaru(14, weight: .black))
                                .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 0.1))
                            Text(NSLocalizedString("certificate_accuracy", comment: ""))
                                .font(.zenMaru(9, weight: .regular))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            VStack(spacing: 4) {
                Text(completionDate)
                    .font(.zenMaru(12, weight: .regular))
                    .foregroundStyle(.secondary)

                Text("certificate_rank")
                    .font(.zenMaru(14, weight: .bold))
                    .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 0.1))
            }

            Text("certificate_logo")
                .font(.zenMaru(16, weight: .black))
                .foregroundStyle(Color(red: 0.8, green: 0.55, blue: 0.15))
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.15), radius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(colors: [
                        Color(red: 0.95, green: 0.85, blue: 0.45),
                        Color(red: 0.85, green: 0.65, blue: 0.25),
                        Color(red: 0.95, green: 0.85, blue: 0.45)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 3
                )
        )
        .padding(.horizontal, 28)
    }

    // MARK: - 画像生成 & シェア

    @MainActor
    private func generateAndShare() {
        let content = ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.85, blue: 0.55),
                    Color(red: 0.85, green: 0.65, blue: 0.30)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            certificateCard
        }
        .frame(width: 390, height: 500)

        let renderer = ImageRenderer(content: content)
        renderer.scale = UIScreen.main.scale
        if let image = renderer.uiImage {
            shareItems = [image]
            showShareSheet = true
        } else {
            shareItems = [NSLocalizedString("certificate_achievement", comment: "")]
            showShareSheet = true
        }
    }
}

// MARK: - UIActivityViewController wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
