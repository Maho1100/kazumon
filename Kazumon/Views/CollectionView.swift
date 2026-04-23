import SwiftUI

struct CollectionView: View {
    let onBack: () -> Void
    @State private var items: [Item] = []
    @State private var showCertificate = false

    var body: some View {
        ZStack {
            // Pastel background
            LinearGradient(
                colors: [
                    Color(red: 0.93, green: 1.0, blue: 0.95),
                    Color(red: 0.95, green: 0.93, blue: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        HapticsManager.tap()
                        onBack()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("view_collection_back")
                        }
                        .font(.zenMaru(17, weight: .bold))
                        .foregroundColor(.blue)
                    }

                    Spacer()

                    Text("view_collection_title")
                        .font(.zenMaru(22, weight: .black))

                    Spacer()

                    // Spacer for balance
                    Text("view_collection_back")
                        .font(.zenMaru(17))
                        .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                // 表彰状ボタン（Day30クリア済みの場合）
                if DataStore.loadChallenge().completedDays.contains(30) {
                    Button {
                        HapticsManager.tap()
                        showCertificate = true
                    } label: {
                        HStack(spacing: 10) {
                            Text("🏆")
                                .font(.system(size: 24))
                            Text("collection_certificate_button")
                                .font(.zenMaru(16, weight: .bold))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.95, blue: 0.8), Color(red: 1.0, green: 0.9, blue: 0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .shadow(color: .orange.opacity(0.2), radius: 4, y: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }

                if items.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("📦")
                            .font(.system(size: 60))
                        Text("view_collection_empty")
                            .font(.zenMaru(20, weight: .bold))
                        Text("view_collection_empty_hint")
                            .font(.zenMaru(15))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ],
                            spacing: 12
                        ) {
                            ForEach(items) { item in
                                itemCard(item)
                            }
                        }
                        .padding(20)
                    }
                }
            }
        }
        .onAppear {
            items = DataStore.loadItems()
        }
        .fullScreenCover(isPresented: $showCertificate) {
            CertificateView(
                playerName: DataStore.loadPlayerData().playerName,
                completionDate: {
                    let f = DateFormatter()
                    f.dateStyle = .long
                    return f.string(from: Date())
                }(),
                onDismiss: { showCertificate = false }
            )
        }
    }

    private func itemCard(_ item: Item) -> some View {
        VStack(spacing: 6) {
            Text(item.emoji)
                .font(.system(size: 40))

            Text(item.localizedName)
                .font(.zenMaru(15, weight: .bold))
                .lineLimit(1)

            Text(item.rarity.star)
                .font(.zenMaru(11))

            if item.count > 1 {
                Text("×\(item.count)")
                    .font(.zenMaru(12))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}
