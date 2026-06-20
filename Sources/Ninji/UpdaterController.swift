import SwiftUI

final class UpdaterController: NSObject, ObservableObject {
    static let shared = UpdaterController()

    @Published private(set) var latestVersion: String?
    @Published private(set) var isChecking = false
    @Published private(set) var updateAvailable = false
    @Published private(set) var errorMessage: String?

    private let repo = "BananabasB/ninji"
    private let versionURL = URL(string: "https://api.github.com/repos/BananabasB/ninji/releases/latest")!

    var currentVersion: String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    func checkForUpdates() {
        isChecking = true
        errorMessage = nil
        latestVersion = nil
        updateAvailable = false

        var request = URLRequest(url: versionURL)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Ninji/\(currentVersion ?? "unknown")", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self else { return }

                if let error = error {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    self.isChecking = false
                    return
                }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tagName = json["tag_name"] as? String else {
                    self.errorMessage = "Could not parse release info"
                    self.isChecking = false
                    return
                }

                let remoteVersion = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
                self.latestVersion = remoteVersion

                if let current = self.currentVersion {
                    self.updateAvailable = self.isNewerVersion(remoteVersion, than: current)
                }

                self.isChecking = false
            }
        }.resume()
    }

    func openReleasePage() {
        let url = URL(string: "https://github.com/\(repo)/releases/latest")!
        NSWorkspace.shared.open(url)
    }

    private func isNewerVersion(_ remote: String, than current: String) -> Bool {
        let remoteParts = remote.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }
        let maxLen = max(remoteParts.count, currentParts.count)
        for i in 0..<maxLen {
            let r = i < remoteParts.count ? remoteParts[i] : 0
            let c = i < currentParts.count ? currentParts[i] : 0
            if r > c { return true }
            if r < c { return false }
        }
        return false
    }
}
