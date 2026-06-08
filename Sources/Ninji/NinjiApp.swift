import SwiftUI
import Sparkle

@main
struct NinjiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var updaterController = UpdaterController.shared

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
