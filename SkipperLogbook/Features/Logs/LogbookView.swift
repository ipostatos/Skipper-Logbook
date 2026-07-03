import SwiftUI
import SwiftData

/// The Logbook tab: a chronological, day-grouped list of log entries with a
/// voyage summary banner and search. Tapping a row opens the entry detail.
struct LogbookView: View {
    @Environment(\.appTheme) private var theme
    @Environment(AppRouter.self) private var router
    @Environment(VoyageRecorder.self) private var recorder

    @Query(sort: \LogEvent.timestamp, order: .reverse) private var allEvents: [LogEvent]
    @Query(sort: \Voyage.startedAt, order: .reverse) private var voyages: [Voyage]
    @Query(sort: \VoiceNote.createdAt, order: .reverse) private var voiceNotes: [VoiceNote]

    @State private var searchText = ""
    @State private var filter: LogFilter = .all
    @State private var showAudioLog = false

    private var activeVoyage: Voyage? {
        recorder.activeVoyage ?? voyages.first
    }

    private var filteredEvents: [LogEvent] {
        var events = allEvents
        if filter != .all && filter != .audio {
            events = events.filter { filter.matches($0.type) }
        }
        if filter == .audio { return [] }   // audio shown from its own query
        guard !searchText.isEmpty else { return events }
        let q = searchText.lowercased()
        return events.filter { e in
            (e.note?.lowercased().contains(q) ?? false)
                || (e.windSummary?.lowercased().contains(q) ?? false)
        }
    }

    /// Events + voice notes merged into one reverse-chronological stream, so a
    /// voice note filed at 10:04 sits between the 09:58 and 10:12 entries.
    /// Notes join only the All filter — Audio has its own dedicated section.
    private var timelineItems: [TimelineItem] {
        var items = filteredEvents.map(TimelineItem.event)
        if filter == .all {
            let q = searchText.lowercased()
            let notes = voiceNotes.filter { q.isEmpty || $0.title.lowercased().contains(q) }
            items.append(contentsOf: notes.map(TimelineItem.voice))
        }
        return items.sorted { $0.timestamp > $1.timestamp }
    }

    private var grouped: [(day: Date, items: [TimelineItem])] {
        Date.groupByDay(timelineItems, date: { $0.timestamp })
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.md, pinnedViews: [.sectionHeaders]) {
                if let voyage = activeVoyage {
                    VoyageSummaryBanner(voyage: voyage)
                        .padding(.horizontal, Spacing.pageMargin)
                }

                filterChips

                if filter == .audio {
                    audioSection
                } else if grouped.isEmpty {
                    EmptyStateView(symbol: "list.bullet.rectangle",
                                   title: "logbook.empty_title",
                                   message: "logbook.empty_message")
                } else {
                    ForEach(grouped, id: \.day) { section in
                        Section {
                            Card(padding: Spacing.xxs) {
                                VStack(spacing: 0) {
                                    ForEach(Array(section.items.enumerated()), id: \.element.id) { i, item in
                                        timelineRow(item)
                                        if i < section.items.count - 1 { Divider().overlay(theme.hairline) }
                                    }
                                }
                            }
                            .padding(.horizontal, Spacing.pageMargin)
                        } header: {
                            Text(section.day.logDayHeader())
                                .font(AppFont.label)
                                .tracking(0.8)
                                .foregroundStyle(theme.inkSecondary)
                                .padding(.horizontal, Spacing.pageMargin)
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(theme.background.opacity(0.95))
                        }
                    }
                }
            }
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.tabBarClearance)
        }
        .background(theme.background)
        .navigationTitle("logbook.title")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: Text("logbook.search_prompt"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAudioLog = true } label: {
                    Image(systemName: "mic.badge.plus")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { router.present(.addLogEvent) } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .navigationDestination(for: EntryRef.self) { ref in
            LogEntryDetailView(eventID: ref.id)
        }
        .sheet(isPresented: $showAudioLog) {
            NavigationStack { AudioLogView() }
        }
    }

    // MARK: Filter chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(LogFilter.allCases) { f in
                    let selected = filter == f
                    Button {
                        withAnimation(.snappy(duration: 0.15)) { filter = f }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: f.symbol).font(.system(size: 12, weight: .semibold))
                            Text(f.titleKey).font(AppFont.subheadline.weight(.medium))
                        }
                        .foregroundStyle(selected ? .white : theme.inkSecondary)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(
                            Capsule().fill(selected ? theme.accent(f.role) : theme.surface)
                        )
                        .overlay(Capsule().strokeBorder(theme.hairline, lineWidth: selected ? 0 : (theme.isDark ? 1 : 0)))
                        .cardShadow(theme)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.pageMargin)
        }
    }

    // MARK: Timeline rows

    @ViewBuilder
    private func timelineRow(_ item: TimelineItem) -> some View {
        switch item {
        case .event(let event):
            NavigationLink(value: EntryRef(id: event.persistentModelID)) {
                LogEventRow(event: event)
            }
            .buttonStyle(.plain)
        case .voice(let note):
            AudioNoteRow(note: note)
        }
    }

    // MARK: Audio section (voice notes folded into Log)

    private var audioSection: some View {
        Group {
            if voiceNotes.isEmpty {
                EmptyStateView(symbol: "waveform", title: "voice.empty_title",
                               message: "voice.empty_message")
            } else {
                Card(padding: Spacing.xxs) {
                    VStack(spacing: 0) {
                        ForEach(Array(voiceNotes.enumerated()), id: \.element.id) { i, note in
                            AudioNoteRow(note: note)
                            if i < voiceNotes.count - 1 { Divider().overlay(theme.hairline) }
                        }
                    }
                }
                .padding(.horizontal, Spacing.pageMargin)
            }
        }
    }
}

/// Log filter categories shown as chips (mirrors the mockup's All / Navigation /
/// Engine / Sails / Safety / Audio filter row).
enum LogFilter: String, CaseIterable, Identifiable {
    case all, navigation, engine, sails, safety, audio
    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .all:        return "filter.all"
        case .navigation: return "filter.navigation"
        case .engine:     return "filter.engine"
        case .sails:      return "filter.sails"
        case .safety:     return "filter.safety"
        case .audio:      return "filter.audio"
        }
    }
    var symbol: String {
        switch self {
        case .all:        return "square.grid.2x2"
        case .navigation: return "location.north.line"
        case .engine:     return "fanblades.fill"
        case .sails:      return "sailboat.fill"
        case .safety:     return "exclamationmark.shield"
        case .audio:      return "mic"
        }
    }
    var role: AccentRole {
        switch self {
        case .all:        return .blue
        case .navigation: return .blue
        case .engine:     return .orange
        case .sails:      return .green
        case .safety:     return .red
        case .audio:      return .purple
        }
    }
    func matches(_ type: LogEventType) -> Bool {
        switch self {
        case .all:   return true
        case .navigation: return [.startTrack, .startLogging, .turnToWaypoint, .waypointReached].contains(type)
        case .engine: return [.engineOn, .engineOff].contains(type)
        case .sails:  return [.sailsUp, .sailsDown, .reef].contains(type)
        case .safety: return [.mob, .anchorDown, .anchorUp, .weather].contains(type)
        case .audio:  return false
        }
    }
}

/// Hashable reference to a log entry for navigation.
struct EntryRef: Hashable { let id: PersistentIdentifier }

/// One row in the merged Logbook timeline: a log entry or a voice note.
private enum TimelineItem: Identifiable {
    case event(LogEvent)
    case voice(VoiceNote)

    var id: PersistentIdentifier {
        switch self {
        case .event(let event): return event.persistentModelID
        case .voice(let note):  return note.persistentModelID
        }
    }

    var timestamp: Date {
        switch self {
        case .event(let event): return event.timestamp
        case .voice(let note):  return note.createdAt
        }
    }
}

/// The voyage summary banner: name + duration / distance / fuel (mirrors the
/// dark "Dragon Winter Series" banner in the mockups).
private struct VoyageSummaryBanner: View {
    @Environment(\.appTheme) private var theme
    let voyage: Voyage

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text(voyage.name).font(AppFont.headline).foregroundStyle(theme.ink)
                    Spacer()
                    if voyage.isRecording {
                        Label("logbook.recording", systemImage: "record.circle")
                            .font(AppFont.caption.weight(.semibold))
                            .foregroundStyle(theme.danger)
                    }
                }
                HStack(spacing: Spacing.xl) {
                    metric(voyage.elapsed.durationDHM, "logbook.duration")
                    metric("\(voyage.distanceNM.oneDecimal) nm", "logbook.distance")
                    metric("\(voyage.engineHours.oneDecimal) h", "logbook.engine")
                }
            }
        }
    }

    private func metric(_ value: String, _ label: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(AppFont.statNumeral).foregroundStyle(theme.ink)
            Text(label).instrumentLabel(theme.inkSecondary)
        }
    }
}

#Preview("Logbook") {
    NavigationStack {
        LogbookView()
            .environment(\.appTheme, .paper)
            .environment(AppRouter())
            .environment(VoyageRecorder(context: PreviewData.container.mainContext))
            .modelContainer(PreviewData.container)
    }
}
