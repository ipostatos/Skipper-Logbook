import SwiftUI

/// The + sheet: a compact grid of the most common actions. Mirrors the
/// dashboard's quick-actions but reachable from any tab.
struct QuickActionsSheet: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @Environment(AppState.self) private var appState
    @Environment(LocationManager.self) private var location
    @Environment(VoyageRecorder.self) private var recorder
    @Environment(MOBEngine.self) private var mob

    @State private var mobNoFix = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("action.quick_actions_title")
                .font(AppFont.headline)
                .foregroundStyle(theme.ink)
                .padding(.top, Spacing.sm)

            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                QuickActionButton(symbol: "note.text", title: "action.event") {
                    dismiss(); router.present(.addLogEvent)
                }
                QuickActionButton(symbol: recorder.engineOn ? "fanblades.fill" : "fanblades",
                                  title: recorder.engineOn ? "action.engine_off" : "action.engine_on") {
                    toggleEngine(); dismiss()
                }
                QuickActionButton(symbol: "sailboat.fill", title: "action.sails") {
                    toggleSails(); dismiss()
                }
                QuickActionButton(symbol: "anchor", title: "action.anchor_watch") {
                    dismiss(); router.present(.anchorWatch)
                }
                QuickActionButton(symbol: recorder.isRecording ? "stop.circle" : "record.circle",
                                  title: recorder.isRecording ? "dash.stop_recording" : "dash.start_recording") {
                    if recorder.isRecording {
                        recorder.stopVoyage(); dismiss()
                    } else {
                        dismiss(); router.present(.newVoyage)
                    }
                }
                QuickActionButton(symbol: "exclamationmark.triangle.fill", title: "action.mob",
                                  isDanger: true, requiresHold: true) {
                    triggerMOB()
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.pageMargin)
        .background(theme.background)
        .alert("mob.no_fix_title", isPresented: $mobNoFix) {
            Button("common.ok", role: .cancel) {}
        } message: { Text("mob.no_fix_message") }
    }

    private func triggerMOB() {
        if mob.trigger(from: location) {
            dismiss(); router.presentMOB()
        } else {
            mobNoFix = true   // keep the sheet up so the alert can explain
        }
    }

    private func toggleEngine() {
        recorder.toggleEngine(sailsUp: appState.mainsailPercent != nil)
    }

    private func toggleSails() {
        if appState.mainsailPercent == nil {
            appState.mainsailPercent = 100; appState.jibPercent = 100
            if recorder.isRecording {
                recorder.addEvent(.sailsUp, at: location.currentCoordinate, mainsailPercent: 100, jibPercent: 100)
            }
        } else {
            appState.mainsailPercent = nil; appState.jibPercent = nil
            if recorder.isRecording { recorder.addEvent(.sailsDown, at: location.currentCoordinate) }
        }
        recorder.setSailState(up: appState.mainsailPercent != nil)
    }
}
