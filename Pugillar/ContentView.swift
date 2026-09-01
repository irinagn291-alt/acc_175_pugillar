import SwiftUI

struct ContentView: View {
    @State private var session = LeafSession.live()

    var body: some View {
        DiptychView(session: session)
    }
}

#Preview {
    ContentView()
}
