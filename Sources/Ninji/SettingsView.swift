import SwiftUI

struct SettingsView: View {
    @AppStorage("enableLogging") private var enableLogging = false
    @AppStorage("enableDiscordRPC") private var enableDiscordRPC = false

    var body: some View {
        TabView {
            LogsSettingsView(enableLogging: $enableLogging)
                .tabItem {
                    Label("Logs", systemImage: "doc.text")
                }

            ThemesSettingsView()
                .tabItem {
                    Label("Themes", systemImage: "paintpalette")
                }

            DiscordSettingsView(enableDiscordRPC: $enableDiscordRPC)
                .tabItem {
                    Label("Discord", systemImage: "bubble.left.and.bubble.right")
                }
        }
        .frame(width: 450, height: 250)
    }
}

struct LogsSettingsView: View {
    @Binding var enableLogging: Bool

    var body: some View {
        Form {
            Section {
                Toggle("Enable Logging", isOn: $enableLogging)
                Text("Logs will be saved to ~/.ninji/track.log")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Track Logging")
            }
        }
        .padding()
    }
}

struct ThemesSettingsView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "paintpalette")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("Themes Coming Soon")
                .font(.headline)
            Text("Custom styles and color schemes are under development.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct DiscordSettingsView: View {
    @Binding var enableDiscordRPC: Bool

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("Discord Rich Presence Coming Soon")
                .font(.headline)
            Text("Discord RPC integration is under development.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
