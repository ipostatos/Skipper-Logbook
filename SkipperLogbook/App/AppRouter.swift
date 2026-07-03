import SwiftUI
import Observation

/// The five bottom-bar destinations. Liquid Nautical order:
/// Today · Map · Log · Vessel · More (with a center + between Map and Log).
enum AppTab: String, CaseIterable, Identifiable {
    case today, map, log, vessel, more
    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .today:  return "tab.today"
        case .map:    return "tab.map"
        case .log:    return "tab.log"
        case .vessel: return "tab.vessel"
        case .more:   return "tab.more"
        }
    }

    var symbol: String {
        switch self {
        case .today:  return "house"
        case .map:    return "map"
        case .log:    return "list.bullet.rectangle"
        case .vessel: return "sailboat"
        case .more:   return "ellipsis"
        }
    }
}

/// Push destinations reachable inside a tab's navigation stack.
enum AppRoute: Hashable {
    case vessel
    case crew
    case maintenance
    case equipment
    case serviceNotes
    case seasonLog
    case deviation
    case statistics
    case settings
    case voyageDetail(PersistentIDBox)
}

/// Modally-presented flows (the + sheet, the full-screen safety flows).
enum SheetRoute: Identifiable {
    case quickActions
    case addLogEvent
    case anchorWatch
    case newVoyage

    var id: String {
        switch self {
        case .quickActions: return "quickActions"
        case .addLogEvent:  return "addLogEvent"
        case .anchorWatch:  return "anchorWatch"
        case .newVoyage:    return "newVoyage"
        }
    }
}

/// A full-screen cover — used for the active MOB search.
enum CoverRoute: Identifiable {
    case mobActive
    var id: String { "mobActive" }
}

/// Owns tab selection, per-tab navigation paths, and modal presentation state.
@Observable
@MainActor
final class AppRouter {
    var selectedTab: AppTab = .today

    // One navigation path per tab so each stack is independent.
    var todayPath = NavigationPath()
    var mapPath = NavigationPath()
    var logPath = NavigationPath()
    var vesselPath = NavigationPath()
    var morePath = NavigationPath()

    var sheet: SheetRoute?
    var cover: CoverRoute?

    func select(_ tab: AppTab) { selectedTab = tab }

    func present(_ sheet: SheetRoute) { self.sheet = sheet }
    func dismissSheet() { sheet = nil }

    func presentMOB() { cover = .mobActive }
    func dismissCover() { cover = nil }

    /// Push a route onto the More tab (its stack hosts most reference screens).
    func pushOnMore(_ route: AppRoute) {
        selectedTab = .more
        morePath.append(route)
    }

    func pushOnToday(_ route: AppRoute) {
        selectedTab = .today
        todayPath.append(route)
    }

    /// Append to the current tab's stack (Vessel tab hosts the boat binder).
    func pushOnVessel(_ route: AppRoute) {
        selectedTab = .vessel
        vesselPath.append(route)
    }

    /// Append to the More stack without switching tabs (used from within it).
    func morePathAppend(_ route: AppRoute) {
        morePath.append(route)
    }

    /// Append onto whichever tab's stack is currently visible — lets a screen
    /// push a child without needing to know which tab hosts it.
    func pushOnActiveTab(_ route: AppRoute) {
        switch selectedTab {
        case .today:  todayPath.append(route)
        case .map:    mapPath.append(route)
        case .log:    logPath.append(route)
        case .vessel: vesselPath.append(route)
        case .more:   morePath.append(route)
        }
    }
}

/// A `Hashable` wrapper for a SwiftData `PersistentIdentifier` so it can travel
/// inside `NavigationPath` / `AppRoute`.
struct PersistentIDBox: Hashable {
    let id: PersistentIdentifier
}
