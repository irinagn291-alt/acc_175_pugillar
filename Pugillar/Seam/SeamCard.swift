import Foundation

/// Role: Seam. Overlay identity. Today's diptych never leaves; these cards sit on it.
enum SeamCard: String, Equatable, Identifiable, Sendable {
    case bond
    case shelf
    case settings
    case seam

    var id: String { rawValue }
}
