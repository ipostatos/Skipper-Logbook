import SwiftUI
import SwiftData

// MARK: - Equipment list

/// Onboard equipment / inventory with optional expiry (raft, flares, EPIRB…).
struct EquipmentListView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var context
    @Query(sort: \EquipmentItem.name) private var items: [EquipmentItem]
    @State private var adding = false
    @State private var itemToDelete: EquipmentItem?

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                if items.isEmpty {
                    EmptyStateView(symbol: "shippingbox", title: "equipment.empty")
                } else {
                    Card(padding: Spacing.xxs) {
                        VStack(spacing: 0) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                                equipmentRow(item)
                                    .contextMenu {
                                        Button(role: .destructive) { itemToDelete = item } label: {
                                            Label("common.delete", systemImage: "trash")
                                        }
                                    }
                                if i < items.count - 1 { Divider().overlay(theme.hairline) }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.pageMargin)
            .padding(.vertical, Spacing.sm)
            .padding(.bottom, Spacing.tabBarClearance)
        }
        .background(theme.background)
        .navigationTitle("more.equipment")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { adding = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $adding) { EquipmentAddSheet() }
        .referenceDeleteDialog(item: $itemToDelete, title: "equipment.delete_confirm", context: context)
    }

    private func equipmentRow(_ item: EquipmentItem) -> some View {
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(AppFont.subheadline).foregroundStyle(theme.ink)
                if let detail = item.detail {
                    Text(detail).font(AppFont.caption).foregroundStyle(theme.inkSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("×\(item.quantity)").font(AppFont.subheadline.monospacedDigit()).foregroundStyle(theme.ink)
                if let exp = item.expiresAt {
                    Text(exp.shortDate()).font(AppFont.caption)
                        .foregroundStyle(exp < .now ? theme.danger : theme.inkSecondary)
                }
            }
        }
        .padding(.vertical, Spacing.sm).padding(.horizontal, Spacing.sm)
    }
}

// MARK: - Service notes

struct ServiceNotesView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var context
    @Query(sort: \ServiceNote.createdAt, order: .reverse) private var notes: [ServiceNote]
    @State private var adding = false
    @State private var noteToDelete: ServiceNote?

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                if notes.isEmpty {
                    EmptyStateView(symbol: "book.closed", title: "service_notes.empty")
                } else {
                    ForEach(notes) { note in
                        Card {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(note.title).font(AppFont.headline).foregroundStyle(theme.ink)
                                    Spacer()
                                    Text(note.createdAt.shortDate()).font(AppFont.caption).foregroundStyle(theme.inkSecondary)
                                }
                                Text(note.body).font(AppFont.subheadline).foregroundStyle(theme.inkSecondary)
                                if let h = note.engineHours {
                                    Text(String(format: String(localized: "service_notes.at_hours"), h.oneDecimal))
                                        .font(AppFont.caption).foregroundStyle(theme.inkTertiary)
                                }
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) { noteToDelete = note } label: {
                                Label("common.delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.pageMargin)
            .padding(.vertical, Spacing.sm)
            .padding(.bottom, Spacing.tabBarClearance)
        }
        .background(theme.background)
        .navigationTitle("more.service_notes")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { adding = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $adding) { ServiceNoteAddSheet() }
        .referenceDeleteDialog(item: $noteToDelete, title: "service_notes.delete_confirm", context: context)
    }
}

// MARK: - Season log

struct SeasonLogView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var context
    @Query(sort: \SeasonLogEntry.startedAt, order: .reverse) private var seasons: [SeasonLogEntry]
    @State private var adding = false
    @State private var seasonToDelete: SeasonLogEntry?

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                if seasons.isEmpty {
                    EmptyStateView(symbol: "sun.max", title: "season.empty")
                } else {
                    ForEach(seasons) { season in
                        Card {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text(season.seasonName).font(AppFont.display(24)).foregroundStyle(theme.ink)
                                HStack(spacing: Spacing.xl) {
                                    metric("\(season.totalDistanceNM.oneDecimal) nm", "season.distance")
                                    metric("\(season.engineHours.oneDecimal) h", "season.engine")
                                }
                                if let notes = season.notes {
                                    Text(notes).font(AppFont.footnote).foregroundStyle(theme.inkSecondary)
                                }
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) { seasonToDelete = season } label: {
                                Label("common.delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.pageMargin)
            .padding(.vertical, Spacing.sm)
            .padding(.bottom, Spacing.tabBarClearance)
        }
        .background(theme.background)
        .navigationTitle("more.season_log")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { adding = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $adding) { SeasonAddSheet() }
        .referenceDeleteDialog(item: $seasonToDelete, title: "season.delete_confirm", context: context)
    }

    private func metric(_ value: String, _ label: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(AppFont.statNumeral).foregroundStyle(theme.ink)
            Text(label).instrumentLabel(theme.inkSecondary)
        }
    }
}

// MARK: - Deviation table

struct DeviationView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var context
    @Query(sort: \DeviationEntry.headingDegrees) private var entries: [DeviationEntry]
    @State private var adding = false
    @State private var entryToDelete: DeviationEntry?

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                Text("deviation.hint").font(AppFont.footnote).foregroundStyle(theme.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if entries.isEmpty {
                    EmptyStateView(symbol: "location.north.circle", title: "deviation.empty")
                } else {
                    Card(padding: Spacing.xxs) {
                        VStack(spacing: 0) {
                            headerRow
                            Divider().overlay(theme.hairline)
                            ForEach(Array(entries.enumerated()), id: \.element.id) { i, entry in
                                deviationRow(entry)
                                    .contextMenu {
                                        Button(role: .destructive) { entryToDelete = entry } label: {
                                            Label("common.delete", systemImage: "trash")
                                        }
                                    }
                                if i < entries.count - 1 { Divider().overlay(theme.hairline) }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.pageMargin)
            .padding(.vertical, Spacing.sm)
            .padding(.bottom, Spacing.tabBarClearance)
        }
        .background(theme.background)
        .navigationTitle("more.deviation")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { adding = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $adding) { DeviationAddSheet() }
        .referenceDeleteDialog(item: $entryToDelete, title: "deviation.delete_confirm", context: context)
    }

    private var headerRow: some View {
        HStack {
            Text("deviation.heading").instrumentLabel(theme.inkSecondary)
            Spacer()
            Text("deviation.value").instrumentLabel(theme.inkSecondary)
        }
        .padding(.vertical, Spacing.sm).padding(.horizontal, Spacing.sm)
    }

    private func deviationRow(_ entry: DeviationEntry) -> some View {
        HStack {
            Text("\(Int(entry.headingDegrees))°")
                .font(AppFont.mono(.subheadline)).foregroundStyle(theme.ink)
            Spacer()
            let d = entry.deviationDegrees
            let ew = d >= 0 ? String(localized: "deviation.east") : String(localized: "deviation.west")
            Text("\(d >= 0 ? "+" : "")\(Int(d))° \(ew)")
                .font(AppFont.mono(.subheadline))
                .foregroundStyle(d == 0 ? theme.inkSecondary : theme.accent)
        }
        .padding(.vertical, Spacing.sm).padding(.horizontal, Spacing.sm)
    }
}

// MARK: - Add sheets (insert on Done only — rule 2.2: no ghost records)

/// New equipment item. Plain local state; nothing touches the store until Done.
struct EquipmentAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var category = ""
    @State private var quantity = 1
    @State private var detail = ""
    @State private var hasExpiry = false
    @State private var expiresAt = Date.now

    var body: some View {
        NavigationStack {
            Form {
                TextField("equipment.name", text: $name)
                TextField("equipment.category", text: $category)
                Stepper(value: $quantity, in: 1...999) {
                    HStack {
                        Text("equipment.quantity")
                        Spacer()
                        Text("×\(quantity)").monospacedDigit().foregroundStyle(.secondary)
                    }
                }
                TextField("equipment.detail", text: $detail, axis: .vertical).lineLimit(2...4)
                Toggle("equipment.has_expiry", isOn: $hasExpiry.animation())
                if hasExpiry {
                    DatePicker("equipment.expires", selection: $expiresAt, displayedComponents: .date)
                }
            }
            .navigationTitle("equipment.add_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") {
                        let trimmedCategory = category.trimmingCharacters(in: .whitespaces)
                        let trimmedDetail = detail.trimmingCharacters(in: .whitespaces)
                        let item = EquipmentItem(name: name.trimmingCharacters(in: .whitespaces),
                                                 category: trimmedCategory.isEmpty ? nil : trimmedCategory,
                                                 quantity: quantity,
                                                 detail: trimmedDetail.isEmpty ? nil : trimmedDetail,
                                                 expiresAt: hasExpiry ? expiresAt : nil)
                        context.insert(item)
                        try? context.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

/// New service note.
struct ServiceNoteAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var title = ""
    @State private var noteBody = ""
    @State private var createdAt = Date.now
    @State private var engineHours: Double?

    var body: some View {
        NavigationStack {
            Form {
                TextField("service_notes.note_title", text: $title)
                TextField("service_notes.body", text: $noteBody, axis: .vertical).lineLimit(3...8)
                DatePicker("service_notes.date", selection: $createdAt, displayedComponents: .date)
                HStack {
                    Text("service_notes.engine_hours")
                    Spacer()
                    TextField("", value: $engineHours, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 120)
                }
            }
            .navigationTitle("service_notes.add_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") {
                        let note = ServiceNote(title: title.trimmingCharacters(in: .whitespaces),
                                               body: noteBody.trimmingCharacters(in: .whitespacesAndNewlines),
                                               createdAt: createdAt,
                                               engineHours: engineHours)
                        context.insert(note)
                        try? context.save()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

/// New season summary.
struct SeasonAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var seasonName = ""
    @State private var startedAt = Date.now
    @State private var hasEnded = false
    @State private var endedAt = Date.now
    @State private var distanceNM: Double?
    @State private var engineHours: Double?
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("season.name", text: $seasonName)
                DatePicker("season.started", selection: $startedAt, displayedComponents: .date)
                Toggle("season.ended_toggle", isOn: $hasEnded.animation())
                if hasEnded {
                    DatePicker("season.ended", selection: $endedAt, displayedComponents: .date)
                }
                ReferenceNumberRow(label: "season.distance", value: $distanceNM)
                ReferenceNumberRow(label: "season.engine", value: $engineHours)
                TextField("season.notes", text: $notes, axis: .vertical).lineLimit(2...5)
            }
            .navigationTitle("season.add_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") {
                        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
                        let entry = SeasonLogEntry(seasonName: seasonName.trimmingCharacters(in: .whitespaces),
                                                   startedAt: startedAt,
                                                   endedAt: hasEnded ? endedAt : nil,
                                                   totalDistanceNM: distanceNM ?? 0,
                                                   engineHours: engineHours ?? 0,
                                                   notes: trimmedNotes.isEmpty ? nil : trimmedNotes)
                        context.insert(entry)
                        try? context.save()
                        dismiss()
                    }
                    .disabled(seasonName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

/// New deviation-table row: ship's head + deviation magnitude with an E/W
/// picker (stored signed: East +, West -).
struct DeviationAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var heading: Double?
    @State private var magnitude: Double?
    @State private var isEast = true

    var body: some View {
        NavigationStack {
            Form {
                ReferenceNumberRow(label: "deviation.heading", value: $heading)
                ReferenceNumberRow(label: "deviation.value", value: $magnitude)
                Picker("deviation.direction", selection: $isEast) {
                    Text("deviation.east").tag(true)
                    Text("deviation.west").tag(false)
                }
                .pickerStyle(.segmented)
            }
            .navigationTitle("deviation.add_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") {
                        let entry = DeviationEntry(headingDegrees: heading ?? 0,
                                                   deviationDegrees: (magnitude ?? 0) * (isEast ? 1 : -1))
                        context.insert(entry)
                        try? context.save()
                        dismiss()
                    }
                    .disabled(heading == nil || magnitude == nil)
                }
            }
        }
    }
}

/// Label + right-aligned decimal field — the add-form counterpart of
/// `VesselEditView.numberField`.
struct ReferenceNumberRow: View {
    let label: LocalizedStringKey
    @Binding var value: Double?

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("", value: $value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120)
        }
    }
}

// MARK: - Shared confirm-then-delete dialog

extension View {
    /// Confirm-then-delete for the reference lists: one dialog per screen,
    /// driven by an optional "pending deletion" model. Deletes + saves on
    /// confirm, clears the binding either way.
    func referenceDeleteDialog<T: PersistentModel>(item: Binding<T?>,
                                                   title: LocalizedStringKey,
                                                   context: ModelContext) -> some View {
        confirmationDialog(title,
                           isPresented: Binding(get: { item.wrappedValue != nil },
                                                set: { if !$0 { item.wrappedValue = nil } }),
                           titleVisibility: .visible) {
            Button("common.delete", role: .destructive) {
                if let model = item.wrappedValue {
                    context.delete(model)
                    try? context.save()
                }
                item.wrappedValue = nil
            }
            Button("common.cancel", role: .cancel) { item.wrappedValue = nil }
        }
    }
}
