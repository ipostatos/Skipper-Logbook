import Foundation

/// Logbook export. **Coming soon** — the surface is stubbed so the UI can wire
/// up the buttons (disabled) without a fake implementation.
protocol LogbookExporter {
    func exportPDF(voyage: Voyage) throws -> URL
    func exportCSV(voyage: Voyage) throws -> URL
}

enum ExportError: Error { case notImplemented }

/// No-op exporter used while PDF/CSV export is not yet available.
struct ExportService: LogbookExporter {
    /// When true, the UI marks export controls as "Coming soon".
    static let isAvailable = false

    func exportPDF(voyage: Voyage) throws -> URL { throw ExportError.notImplemented }
    func exportCSV(voyage: Voyage) throws -> URL { throw ExportError.notImplemented }
}
