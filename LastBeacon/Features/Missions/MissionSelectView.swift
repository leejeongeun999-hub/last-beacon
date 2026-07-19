import SwiftUI

struct MissionSelectView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Button("common.back") { model.goHome() }
                    .accessibilityIdentifier("missions.back")
                Spacer()
                Text("missions.title").font(.title2.bold())
                Spacer()
                Color.clear.frame(width: 44, height: 1)
            }

            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(1...3, id: \.self) { sector in
                        sectorView(sector)
                    }
                }
            }
        }
        .padding()
        .neonBackground()
    }

    private func sectorView(_ sector: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(format: String(localized: "missions.sector"), Int64(sector)))
                .font(.headline)
                .foregroundStyle(NeonTheme.cyan)
            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                ForEach(model.catalog.missions.filter { $0.sector == sector }) { mission in
                    missionButton(mission)
                }
            }
        }
    }

    private func missionButton(_ mission: MissionDefinition) -> some View {
        let number = (model.catalog.missions.firstIndex(of: mission) ?? 0) % 4 + 1
        let unlocked = model.isMissionUnlocked(mission)
        return Button {
            model.start(mission: mission)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: unlocked ? "antenna.radiowaves.left.and.right" : "lock.fill")
                    .font(.title2)
                Text(String(format: String(localized: "missions.mission"), Int64(number)))
                    .font(.headline)
                Text("★ \(model.document.progression.stars(for: mission.id))/3")
                    .foregroundStyle(NeonTheme.amber)
            }
            .frame(maxWidth: .infinity, minHeight: 104)
            .background(NeonTheme.panel, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(unlocked == false)
        .accessibilityIdentifier("mission.\(mission.id)")
    }
}

