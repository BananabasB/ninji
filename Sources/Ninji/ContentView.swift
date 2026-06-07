import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            WebView(url: URL(string: "https://music.nintendo.com")!)
            WindowAccessor()
                .frame(width: 0, height: 0)
        }
        .edgesIgnoringSafeArea(.all)
    }
}
