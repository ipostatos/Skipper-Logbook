import WidgetKit
import SwiftUI

/// The widget extension bundle: home-screen / lock-screen widgets plus the
/// active-voyage Live Activity.
@main
struct SkipperWidgetBundle: WidgetBundle {
    var body: some Widget {
        ActiveVoyageWidget()
        MaintenanceWidget()
        LogbookStreakWidget()
        VoyageLiveActivity()
    }
}
