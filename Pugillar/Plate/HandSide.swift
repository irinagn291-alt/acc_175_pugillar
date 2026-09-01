import Foundation

/// Role: Plate. The two hands on one diptych. Alpha always writes before beta unlocks on prompts.
enum HandSide: String, Codable, Sendable, CaseIterable, Identifiable {
    case alpha
    case beta

    var id: String { rawValue }
}
