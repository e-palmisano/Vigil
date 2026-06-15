import AppKit
import Foundation

@MainActor
final class UpdateCheckerService {
    private let currentVersion: String
    private var periodicTimer: Timer?

    private let releasesURL = URL(string: "https://api.github.com/repos/e-palmisano/Vigil/releases/latest")!

    private static let brewCaskroomPaths = [
        "/opt/homebrew/Caskroom/vigil",
        "/usr/local/Caskroom/vigil"
    ]

    init() {
        currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    func startPeriodicChecks() {
        Task { await performCheck(userInitiated: false) }
        periodicTimer = Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.performCheck(userInitiated: false) }
        }
    }

    func checkNow() {
        Task { await performCheck(userInitiated: true) }
    }

    private func performCheck(userInitiated: Bool) async {
        do {
            let release = try await fetchLatestRelease()
            let latest = release.tagName.hasPrefix("v") ? String(release.tagName.dropFirst()) : release.tagName
            guard isNewer(latest) else {
                if userInitiated { showUpToDateAlert() }
                return
            }
            let brewManaged = Self.brewCaskroomPaths.contains {
                FileManager.default.fileExists(atPath: $0)
            }
            showUpdateAlert(latestVersion: latest, brewManaged: brewManaged, releaseURL: release.htmlURL)
        } catch {
            if userInitiated { showNetworkErrorAlert() }
        }
    }

    private func fetchLatestRelease() async throws -> GitHubRelease {
        var request = URLRequest(url: releasesURL)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(GitHubRelease.self, from: data)
    }

    private func isNewer(_ remote: String) -> Bool {
        remote.compare(currentVersion, options: .numeric) == .orderedDescending
    }

    private func showUpdateAlert(latestVersion: String, brewManaged: Bool, releaseURL: String) {
        let alert = NSAlert()
        alert.messageText = "Vigil \(latestVersion) Available"
        alert.informativeText = brewManaged
            ? "You're running \(currentVersion). Run the command below or download the DMG."
            : "You're running \(currentVersion). Download the latest release from GitHub."
        alert.alertStyle = .informational
        alert.addButton(withTitle: brewManaged ? "Copy brew command" : "Download")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            if brewManaged {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString("brew upgrade --cask vigil", forType: .string)
            } else if let url = URL(string: releaseURL) {
                NSWorkspace.shared.open(url)
            }
        }
    }

    private func showUpToDateAlert() {
        let alert = NSAlert()
        alert.messageText = "Vigil is Up to Date"
        alert.informativeText = "You're running the latest version (\(currentVersion))."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func showNetworkErrorAlert() {
        let alert = NSAlert()
        alert.messageText = "Update Check Failed"
        alert.informativeText = "Could not reach GitHub. Check your internet connection and try again."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

private struct GitHubRelease: Decodable {
    let tagName: String
    let htmlURL: String

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
    }
}
