import SwiftUI
@testable import Pugillar

enum ScreenCatalog {
    @MainActor
    static var shots: [(String, AnyView)] {
        [
            ("diptych", AnyView(DiptychView())),
            ("shelf", AnyView(ShelfView())),
            ("bond", AnyView(BondView())),
            ("settings", AnyView(SettingsView()))
        ]
    }
}
