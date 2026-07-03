import SwiftUI
import SwiftData

/// The vessel screen (Судно): photo, name/type, and the spec table
/// (registration, MMSI, call sign, dimensions, engine, tank). Links to Crew and
/// Maintenance. Editable via the toolbar.
struct VesselView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var context
    @Environment(AppRouter.self) private var router
    @Query private var vessels: [Vessel]
    @State private var editing = false

    private var vessel: Vessel? { vessels.first }

    var body: some View {
        ScrollView {
            if let vessel {
                VStack(spacing: Spacing.md) {
                    photo(vessel)
                    header(vessel)
                    specTable(vessel)
                    if let notes = vessel.notes, !notes.isEmpty { notesCard(notes) }
                    links
                }
                .padding(.horizontal, Spacing.pageMargin)
                .padding(.bottom, Spacing.tabBarClearance)
            } else {
                VStack(spacing: Spacing.md) {
                    EmptyStateView(symbol: "sailboat", title: "vessel.empty",
                                   message: "vessel.empty_message")
                    PrimaryButton(title: "vessel.add", symbol: "plus", role: .accent) {
                        createVessel()
                    }
                }
                .padding(.horizontal, Spacing.pageMargin)
            }
        }
        .background(theme.background)
        .navigationTitle("vessel.title")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if vessel != nil { Button("common.edit") { editing = true } }
            }
        }
        .sheet(isPresented: $editing) {
            if let vessel { VesselEditView(vessel: vessel) }
        }
    }

    private func photo(_ vessel: Vessel) -> some View {
        Group {
            if let data = vessel.photoData, let img = UIImage(data: data) {
                Image(uiImage: img).resizable().scaledToFill()
            } else {
                ZStack {
                    theme.accentSoft
                    Image(systemName: "sailboat.fill")
                        .font(.system(size: 48)).foregroundStyle(theme.accent.opacity(0.5))
                }
            }
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
    }

    private func header(_ vessel: Vessel) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(vessel.name).font(AppFont.display(28)).foregroundStyle(theme.ink)
            Text(vessel.type).font(AppFont.subheadline).foregroundStyle(theme.inkSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func specTable(_ vessel: Vessel) -> some View {
        Card(padding: Spacing.xs) {
            VStack(spacing: 0) {
                specRow("vessel.registration", vessel.registration)
                specRow("vessel.mmsi", vessel.mmsi)
                specRow("vessel.call_sign", vessel.callSign)
                specRow("vessel.length", vessel.lengthMeters.map { "\($0.formatted(2)) m" })
                specRow("vessel.beam", vessel.beamMeters.map { "\($0.formatted(2)) m" })
                specRow("vessel.draft", vessel.draftMeters.map { "\($0.formatted(2)) m" })
                specRow("vessel.engine", vessel.engineModel)
                specRow("vessel.fuel_tank", vessel.fuelCapacityLiters.map { "\(Int($0)) L" })
                specRow("vessel.water_tank", vessel.waterCapacityLiters.map { "\(Int($0)) L" }, last: true)
            }
        }
    }

    private func notesCard(_ notes: String) -> some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                SectionHeader("vessel.notes")
                Text(notes).font(AppFont.subheadline).foregroundStyle(theme.ink)
            }
        }
    }

    private func createVessel() {
        let vessel = Vessel(name: String(localized: "vessel.default_name"))
        context.insert(vessel)
        try? context.save()
        editing = true
    }

    @ViewBuilder
    private func specRow(_ label: LocalizedStringKey, _ value: String?, last: Bool = false) -> some View {
        InfoRow(label: label, value: value ?? "—", monospacedValue: true)
        if !last { Divider().overlay(theme.hairline) }
    }

    private var links: some View {
        Card(padding: Spacing.xxs) {
            VStack(spacing: 0) {
                Button { router.pushOnActiveTab(.crew) } label: {
                    InfoRow(symbol: "person.2", label: "more.crew", value: "", showsChevron: true)
                }.buttonStyle(.plain)
                Divider().overlay(theme.hairline)
                Button { router.pushOnActiveTab(.maintenance) } label: {
                    InfoRow(symbol: "wrench.and.screwdriver", label: "more.engine_log", value: "", showsChevron: true)
                }.buttonStyle(.plain)
            }
        }
    }
}

#Preview("Vessel") {
    NavigationStack {
        VesselView()
            .environment(\.appTheme, .paper)
            .environment(AppRouter())
            .modelContainer(PreviewData.container)
    }
}
