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
            
            UpdatesSettingsView()
                .tabItem {
                    Label("Updates", systemImage: "arrow.triangle.2.circlepath")
                }
        }
        .frame(width: 450, height: 200)
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

struct UpdatesSettingsView: View {
    @State private var currentVersion: String = "Unknown"
    @State private var isChecking = false
    @State private var checkMessage: String? = nil

    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 2) {
                Text("Ninji Updater")
                    .font(.headline)
                Text("Version: \(currentVersion)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if isChecking {
                ProgressView()
                    .controlSize(.small)
            }
            
            if let message = checkMessage {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: checkForUpdates) {
                Text("Check for Updates")
                    .frame(maxWidth: .infinity)
            }
            .disabled(isChecking)
            
            Text("Automatic updates enabled")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .onAppear {
            currentVersion = UpdaterController.shared.currentVersion ?? "Unknown"
        }
    }
    
    private func checkForUpdates() {
        isChecking = true
        checkMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UpdaterController.shared.checkForUpdates()
            isChecking = false
            checkMessage = "Checked for updates"
        }
    }
}
