import Foundation

/// FORK: stores which document cards are visible in the Documents tab.
/// Default state (first launch):
///   - passport        = ON
///   - birthCertificate = ON
///   - driverLicense   = OFF
///
/// Toggling a switch in Settings → "Картки документів" calls `setVisible(_:for:)`
/// and the next launch of the Documents tab will reflect the change.
final class DocumentVisibilityStorage {

    static let shared = DocumentVisibilityStorage()

    private let defaults = UserDefaults.standard

    /// Document types the user can show/hide in the fork.
    enum DocKind: String, CaseIterable {
        case passport
        case birthCertificate
        case driverLicense

        var displayName: String {
            switch self {
            case .passport:           return "Паспорт громадянина України"
            case .birthCertificate:   return "Актовий запис про народження"
            case .driverLicense:      return "Посвідчення водія"
            }
        }

        var iconName: String {
            switch self {
            case .passport:           return "menuDiiaID"
            case .birthCertificate:   return "orderIcon"
            case .driverLicense:      return "orderIcon"
            }
        }

        /// Initial visibility for a fresh install.
        var defaultIsVisible: Bool {
            switch self {
            case .passport, .birthCertificate: return true
            case .driverLicense:               return false
            }
        }
    }

    private init() {}

    func isVisible(_ kind: DocKind) -> Bool {
        if defaults.object(forKey: keyFor(kind)) == nil {
            return kind.defaultIsVisible
        }
        return defaults.bool(forKey: keyFor(kind))
    }

    func setVisible(_ visible: Bool, for kind: DocKind) {
        defaults.set(visible, forKey: keyFor(kind))
    }

    /// Snapshot of current visibility for all kinds — used by Settings
    /// to build the toggle rows without re-querying UserDefaults per row.
    func snapshot() -> [(kind: DocKind, isVisible: Bool)] {
        DocKind.allCases.map { ($0, isVisible($0)) }
    }

    private func keyFor(_ kind: DocKind) -> String {
        "fork.docVisibility.\(kind.rawValue)"
    }
}
