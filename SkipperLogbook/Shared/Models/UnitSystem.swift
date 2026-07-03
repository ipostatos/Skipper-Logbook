import Foundation

/// Preferred units for display. Nautical is the default for a sailing app.
enum UnitSystem: String, Codable, CaseIterable, Identifiable {
    case nautical   // knots, nautical miles
    case metric     // km/h, kilometres
    case imperial   // mph, statute miles

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .nautical: return "units.nautical"
        case .metric:   return "units.metric"
        case .imperial: return "units.imperial"
        }
    }
}

/// How a leg of a voyage was propelled — used for the Statistics breakdown
/// (Engine / Sails / Sails & Engine / Idle-Drift).
enum PropulsionMode: String, Codable, CaseIterable, Identifiable {
    case engine
    case sails
    case sailsAndEngine
    case idle

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .engine:         return "propulsion.engine"
        case .sails:          return "propulsion.sails"
        case .sailsAndEngine: return "propulsion.sails_engine"
        case .idle:           return "propulsion.idle"
        }
    }

    var symbol: String {
        switch self {
        case .engine:         return "fanblades.fill"
        case .sails:          return "sailboat.fill"
        case .sailsAndEngine: return "sailboat.fill"
        case .idle:           return "pause.circle"
        }
    }
}
