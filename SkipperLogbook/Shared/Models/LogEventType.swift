import SwiftUI

/// The kind of a logbook entry. Drives the row icon, tint and default title.
/// Stored raw in SwiftData via its `String` raw value.
enum LogEventType: String, Codable, CaseIterable, Identifiable {
    case startTrack        // "Start record track"
    case startLogging      // "Start logging"
    case engineOn
    case engineOff
    case sailsUp           // one or more sails set / reefed (carries sail state)
    case sailsDown
    case reef              // reef taken / shaken
    case turnToWaypoint
    case waypointReached
    case anchorDown
    case anchorUp
    case weather           // wind / weather observation
    case mob
    case note              // free-text / voice-linked note
    case custom

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .startTrack:      return "event.start_track"
        case .startLogging:    return "event.start_logging"
        case .engineOn:        return "event.engine_on"
        case .engineOff:       return "event.engine_off"
        case .sailsUp:         return "event.sails_up"
        case .sailsDown:       return "event.sails_down"
        case .reef:            return "event.reef"
        case .turnToWaypoint:  return "event.turn_to_waypoint"
        case .waypointReached: return "event.waypoint_reached"
        case .anchorDown:      return "event.anchor_down"
        case .anchorUp:        return "event.anchor_up"
        case .weather:         return "event.weather"
        case .mob:             return "event.mob"
        case .note:            return "event.note"
        case .custom:          return "event.custom"
        }
    }

    var symbol: String {
        switch self {
        case .startTrack:      return "record.circle"
        case .startLogging:    return "text.line.first.and.arrowtriangle.forward"
        case .engineOn:        return "fanblades.fill"
        case .engineOff:       return "fanblades"
        case .sailsUp:         return "sailboat.fill"
        case .sailsDown:       return "sailboat"
        case .reef:            return "wind"
        case .turnToWaypoint:  return "arrow.turn.up.right"
        case .waypointReached: return "flag.checkered"
        case .anchorDown:      return "anchor.fill"
        case .anchorUp:        return "anchor"
        case .weather:         return "wind"
        case .mob:             return "figure.wave"
        case .note:            return "note.text"
        case .custom:          return "circle"
        }
    }

    /// Semantic tint role, resolved against the active theme by the row view.
    enum Tint { case ink, accent, sail, success, danger }

    var tint: Tint {
        switch self {
        case .engineOn:                    return .success
        case .engineOff, .anchorUp:        return .ink
        case .sailsUp, .reef:              return .sail
        case .mob:                         return .danger
        case .turnToWaypoint, .waypointReached, .startTrack, .startLogging:
            return .accent
        default:                           return .ink
        }
    }

    /// Whether the composer should offer the sail-percentage controls.
    var carriesSailState: Bool {
        self == .sailsUp || self == .sailsDown || self == .reef
    }
}

extension LogEventType.Tint {
    /// Resolves the semantic tint against the active theme.
    func color(_ theme: AppTheme) -> Color {
        switch self {
        case .ink:     return theme.ink
        case .accent:  return theme.accent
        case .sail:    return theme.sail
        case .success: return theme.success
        case .danger:  return theme.danger
        }
    }
}
