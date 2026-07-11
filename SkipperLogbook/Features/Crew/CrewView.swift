import SwiftUI
import SwiftData

/// The crew list (Экипаж): avatar, name, role, phone, with add/edit.
struct CrewView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var context
    @Query(sort: \CrewMember.sortIndex) private var crew: [CrewMember]
    @Query private var vessels: [Vessel]

    @State private var editing: CrewMember?
    @State private var addingNew = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                if crew.isEmpty {
                    EmptyStateView(symbol: "person.2", title: "crew.empty")
                } else {
                    Card(padding: Spacing.xxs) {
                        VStack(spacing: 0) {
                            ForEach(Array(crew.enumerated()), id: \.element.id) { i, member in
                                Button { editing = member } label: {
                                    CrewMemberRow(member: member)
                                }
                                .buttonStyle(.plain)
                                if i < crew.count - 1 { Divider().overlay(theme.hairline) }
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
        .navigationTitle("crew.title")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { addingNew = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(item: $editing) { member in
            CrewMemberEditView(member: member)
        }
        .sheet(isPresented: $addingNew) {
            // The member is inserted only on Done (inside the add view) — a
            // swipe-down cancel must not leave a persisted blank row behind.
            CrewMemberAddView(sortIndex: crew.count, vessel: vessels.first)
        }
    }
}

/// Add a new crew member: plain local state, nothing touches the store until
/// Done. (Inserting inside the sheet's ViewBuilder used to persist "ghost"
/// members on swipe-dismiss.)
struct CrewMemberAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let sortIndex: Int
    let vessel: Vessel?

    @State private var name = ""
    @State private var role = ""
    @State private var phone = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("crew.details") {
                    TextField("crew.name", text: $name)
                    TextField("crew.role", text: $role)
                    TextField("crew.phone", text: $phone)
                        .keyboardType(.phonePad)
                }
            }
            .navigationTitle("crew.edit_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") {
                        let member = CrewMember(name: name.trimmingCharacters(in: .whitespaces),
                                                role: role, sortIndex: sortIndex)
                        let trimmedPhone = phone.trimmingCharacters(in: .whitespaces)
                        member.phone = trimmedPhone.isEmpty ? nil : trimmedPhone
                        member.vessel = vessel
                        context.insert(member)
                        try? context.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

/// A crew row: avatar + name + role + phone.
struct CrewMemberRow: View {
    @Environment(\.appTheme) private var theme
    let member: CrewMember

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Avatar(imageData: member.avatarData, initials: member.initials)
            VStack(alignment: .leading, spacing: 2) {
                Text(member.name).font(AppFont.subheadline.weight(.semibold)).foregroundStyle(theme.ink)
                Text(member.role).font(AppFont.caption).foregroundStyle(theme.inkSecondary)
                if let phone = member.phone {
                    Text(phone).font(AppFont.caption.monospacedDigit()).foregroundStyle(theme.inkTertiary)
                }
            }
            Spacer()
            Image(systemName: "pencil").font(.system(size: 14)).foregroundStyle(theme.inkTertiary)
        }
        .padding(.vertical, Spacing.sm).padding(.horizontal, Spacing.sm)
    }
}

/// Add / edit a crew member.
struct CrewMemberEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var member: CrewMember
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section("crew.details") {
                    TextField("crew.name", text: $member.name)
                    TextField("crew.role", text: $member.role)
                    TextField("crew.phone", text: Binding.optionalText($member.phone))
                        .keyboardType(.phonePad)
                }
                Section {
                    Button("crew.delete", role: .destructive) { confirmDelete = true }
                }
            }
            .navigationTitle("crew.edit_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") { try? context.save(); dismiss() }
                        .disabled(member.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("crew.delete_confirm", isPresented: $confirmDelete,
                                titleVisibility: .visible) {
                Button("crew.delete", role: .destructive) {
                    context.delete(member); try? context.save(); dismiss()
                }
                Button("common.cancel", role: .cancel) {}
            }
        }
    }
}

#Preview("Crew") {
    NavigationStack {
        CrewView()
            .environment(\.appTheme, .paper)
            .modelContainer(PreviewData.container)
    }
}
