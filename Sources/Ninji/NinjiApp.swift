import SwiftUI
import Sparkle

@main
struct NinjiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1200, minHeight: 800)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)

        Settings {
            SettingsView()
        }

        .commands {
            CommandMenu("Ninji") {
                Button("Open Shared Playlist…") {
                    appDelegate.openSharedPlaylist()
                }
                .keyboardShortcut("O", modifiers: [.command, .shift])
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        // Start Discord RPC
        DiscordRPC.shared.startIfNeeded()
        
        // Start Sparkle updater
        UpdaterController.shared.start()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            NSApp.activate(ignoringOtherApps: true)
        }
        return true
    }

    // Prompt for a Nintendo Music share URL, resolve it if necessary, and open in the app's web view
    func openSharedPlaylist() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Open Shared Playlist"
            alert.informativeText = "Paste a Nintendo Music sharing link or a user-playlist URL:"
            alert.alertStyle = .informational

            let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 480, height: 24))
            input.stringValue = ""
            alert.accessoryView = input

            alert.addButton(withTitle: "Open")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                let pasted = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard let url = URL(string: pasted) else { return }
                resolveAndOpenSharedURL(url)
            }
        }
    }

    private func resolveAndOpenSharedURL(_ url: URL) {
        // If it's a Nintendo share URL, fetch and extract the inner href
        if let host = url.host, host.contains("share.music.nintendo.com") || host.contains("share.music.nintendo") {
            let task = URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data = data, let html = String(data: data, encoding: .utf8) else {
                    DispatchQueue.main.async {
                        WebViewManager.shared.webView.load(URLRequest(url: url))
                        NSApp.activate(ignoringOtherApps: true)
                    }
                    return
                }

                let pattern = "<a[^>]*class=\\\"[^\\\"]*_17osqud9[^\\\"]*\\\"[^>]*href=\\\"([^"]+)\\\""
                if let re = try? NSRegularExpression(pattern: pattern, options: []),
                   let m = re.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
                   m.numberOfRanges >= 2,
                   let r = Range(m.range(at: 1), in: html) {
                    let href = String(html[r])
                    var finalURL = URL(string: href)
                    if finalURL == nil && href.hasPrefix("/") {
                        finalURL = URL(string: "https://music.nintendo.com" + href)
                    }

                    if let final = finalURL {
                        DispatchQueue.main.async {
                            WebViewManager.shared.webView.load(URLRequest(url: final))
                            NSApp.activate(ignoringOtherApps: true)
                        }
                        return
                    }
                }

                // Fallback: open the original URL
                DispatchQueue.main.async {
                    WebViewManager.shared.webView.load(URLRequest(url: url))
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
            task.resume()
        } else {
            // Directly open provided URL
            DispatchQueue.main.async {
                WebViewManager.shared.webView.load(URLRequest(url: url))
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}

struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                self.setupWindow(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let window = nsView.window {
            self.setupWindow(window)
        }
    }

    private func setupWindow(_ window: NSWindow) {
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
        window.isMovableByWindowBackground = true
        window.setFrameAutosaveName("NinjiMainWindow")

        positionTrafficLights(for: window)

        NotificationCenter.default.removeObserver(window, name: NSWindow.didResizeNotification, object: window)
        NotificationCenter.default.addObserver(forName: NSWindow.didResizeNotification, object: window, queue: .main) { _ in
            self.positionTrafficLights(for: window)
        }
    }

    private func positionTrafficLights(for window: NSWindow) {
        if let titlebarView = window.standardWindowButton(.closeButton)?.superview {
            let xOffset: CGFloat = 18
            let yOffset: CGFloat = 18

            let closeButton = window.standardWindowButton(.closeButton)
            let miniaturizeButton = window.standardWindowButton(.miniaturizeButton)
            let zoomButton = window.standardWindowButton(.zoomButton)

            let buttons = [closeButton, miniaturizeButton, zoomButton]
            var currentX = xOffset

            for button in buttons {
                if let btn = button {
                    var frame = btn.frame
                    frame.origin.x = currentX
                    frame.origin.y = titlebarView.frame.height - frame.height - yOffset
                    btn.setFrameOrigin(frame.origin)
                    currentX += frame.width + 8.5
                }
            }
        }
    }
}
