import SwiftUI

struct TabBarView: View {
    @Binding var currentTab: KazumonTab
    let totalXP: Int
    let newlyUnlockedTab: KazumonTab?
    // パルス用コールバック
    var onTabTapped: ((KazumonTab) -> Void)? = nil
    var isTabPulsing: ((KazumonTab) -> Bool)? = nil

    var body: some View {
        HStack(spacing: 0) {
            ForEach(KazumonTab.allCases, id: \.self) { tab in
                let unlocked = tab.isUnlocked(totalXP: totalXP)
                let pulsing = isTabPulsing?(tab) ?? false

                Button {
                    guard unlocked else { return }
                    HapticsManager.tap()
                    onTabTapped?(tab)
                    currentTab = tab
                } label: {
                    VStack(spacing: 0) {
                        if unlocked {
                            Image(systemName: tab.icon)
                                .font(.system(size: 22))
                                .foregroundColor(currentTab == tab ? .blue : .gray)
                        } else {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color.gray.opacity(0.4))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        currentTab == tab
                            ? Color.blue.opacity(0.08)
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    // パルスアニメーション（解放済み・未タップのみ）
                    .modifier(PulsingModifier(active: pulsing))
                }
                .buttonStyle(.plain)
                .disabled(!unlocked)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.08), radius: 8, y: -2)
        )
    }
}

// MARK: - PulsingModifier
private struct PulsingModifier: ViewModifier {
    let active: Bool
    @State private var animating: Bool = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(animating ? 1.2 : 1.0)
            .brightness(animating ? 0.15 : 0.0)
            .onAppear {
                if active { startAnimation() }
            }
            .onChange(of: active) { _, newValue in
                if newValue {
                    startAnimation()
                } else {
                    stopAnimation()
                }
            }
    }

    private func startAnimation() {
        guard !animating else { return }
        withAnimation(
            .easeInOut(duration: 0.6)
            .repeatForever(autoreverses: true)
        ) {
            animating = true
        }
    }

    private func stopAnimation() {
        withAnimation(.easeOut(duration: 0.2)) {
            animating = false
        }
    }
}
