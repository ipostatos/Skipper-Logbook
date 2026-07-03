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
            CrewMemberEditView(member: newMember())
        }
    }

    private func newMember() -> CrewMember {
        let member = CrewMember(name: "", role: "", sortIndex: crew.count)
        member.vessel = vessels.first
        context.insert(member)
        return member
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
                    Button("crew.delete", role: .destructive) {
                        context.delete(member); try? context.save(); dismiss()
                    }
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
