import AppKit
import Foundation

@MainActor
final class UpdateCheckerService {
    private let currentVersion: String
    private var periodicTimer: Timer?
    private var progressPanel: NSPanel?

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

    // MARK: - Check

    private func performCheck(userInitiated: Bool) async {
        do {
            let release = try await fetchLatestRelease()
            let latest = release.tagName.hasPrefix("v") ? String(release.tagName.dropFirst()) : release.tagName
            guard isNewer(latest) else {
                if userInitiated { showUpToDateAlert() }
                return
            }
            let brewManaged = Self.brewCaskroomPaths.contains { FileManager.default.fileExists(atPath: $0) }
            let dmgAsset = release.assets.first { $0.name.hasSuffix(".dmg") }
            showUpdateAlert(latestVersion: latest, brewManaged: brewManaged,
                            dmgURL: dmgAsset?.browserDownloadURL, releaseURL: release.htmlURL)
        } catch {
            if userInitiated { showNetworkErrorAlert() }
        }
    }

    // MARK: - Alerts

    private func showUpdateAlert(latestVersion: String, brewManaged: Bool, dmgURL: String?, releaseURL: String) {
        let alert = NSAlert()
        alert.messageText = "Vigil \(latestVersion) Available"
        alert.alertStyle = .informational

        if brewManaged {
            alert.informativeText = "You're running \(currentVersion). Run the command below in Terminal."
            alert.addButton(withTitle: "Copy brew command")
            alert.addButton(withTitle: "Later")
            if alert.runModal() == .alertFirstButtonReturn {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString("brew upgrade --cask vigil", forType: .string)
            }
        } else if let dmgURL {
            alert.informativeText = "You're running \(currentVersion). Vigil will download the update and restart."
            alert.addButton(withTitle: "Update Now")
            alert.addButton(withTitle: "Later")
            if alert.runModal() == .alertFirstButtonReturn {
                Task { await self.downloadAndInstall(dmgURLString: dmgURL, version: latestVersion) }
            }
        } else if let url = URL(string: releaseURL) {
            alert.informativeText = "You're running \(currentVersion). Download the latest release from GitHub."
            alert.addButton(withTitle: "Download")
            alert.addButton(withTitle: "Later")
            if alert.runModal() == .alertFirstButtonReturn {
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
        alert.informativeText = "Could not reach GitHub. Check your internet connection."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func showInstallErrorAlert() {
        let alert = NSAlert()
        alert.messageText = "Update Failed"
        alert.informativeText = "Could not install the update automatically. Try downloading manually."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open GitHub")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn,
           let url = URL(string: "https://github.com/e-palmisano/Vigil/releases/latest") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Download & Install

    private func downloadAndInstall(dmgURLString: String, version: String) async {
        guard let dmgURL = URL(string: dmgURLString) else { return }
        showProgressPanel(message: "Downloading Vigil \(version)…")
        do {
            let (localURL, _) = try await URLSession.shared.download(from: dmgURL)
            updateProgressPanel(message: "Installing…")
            try await mountAndInstall(dmgPath: localURL.path)
        } catch {
            hideProgressPanel()
            showInstallErrorAlert()
        }
    }

    private func mountAndInstall(dmgPath: String) async throws {
        let plist = try await runProcess("/usr/bin/hdiutil", ["attach", dmgPath, "-nobrowse", "-plist", "-quiet"])
        let mountPoint = try parseMountPoint(from: plist)

        defer {
            Task { try? await runProcess("/usr/bin/hdiutil", ["detach", mountPoint, "-quiet"]) }
        }

        let sourceApp = URL(filePath: "\(mountPoint)/Vigil.app")
        let destApp = Bundle.main.bundleURL
        let fm = FileManager.default
        guard fm.fileExists(atPath: sourceApp.path) else { throw UpdateError.appNotFound }

        let tmpApp = destApp.deletingLastPathComponent().appendingPathComponent(".Vigil-update.app")
        if fm.fileExists(atPath: tmpApp.path) { try fm.removeItem(at: tmpApp) }
        try fm.copyItem(at: sourceApp, to: tmpApp)
        _ = try fm.replaceItemAt(destApp, withItemAt: tmpApp)

        hideProgressPanel()

        let task = Process()
        task.executableURL = URL(filePath: "/usr/bin/open")
        task.arguments = ["-n", destApp.path]
        try task.run()
        NSApp.terminate(nil)
    }

    // MARK: - Progress Panel

    private func showProgressPanel(message: String) {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 72),
            styleMask: [.titled, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "Vigil Update"
        panel.isFloatingPanel = true
        panel.isReleasedWhenClosed = false
        panel.center()

        let spinner = NSProgressIndicator(frame: NSRect(x: 16, y: 22, width: 24, height: 24))
        spinner.style = .spinning
        spinner.isIndeterminate = true
        spinner.startAnimation(nil)

        let label = NSTextField(labelWithString: message)
        label.frame = NSRect(x: 52, y: 26, width: 272, height: 20)
        label.tag = 1001

        panel.contentView?.addSubview(spinner)
        panel.contentView?.addSubview(label)
        panel.makeKeyAndOrderFront(nil)
        progressPanel = panel
    }

    private func updateProgressPanel(message: String) {
        (progressPanel?.contentView?.viewWithTag(1001) as? NSTextField)?.stringValue = message
    }

    private func hideProgressPanel() {
        progressPanel?.orderOut(nil)
        progressPanel = nil
    }

    // MARK: - Helpers

    @discardableResult
    private func runProcess(_ executable: String, _ arguments: [String]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(filePath: executable)
            process.arguments = arguments
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe()
            process.terminationHandler = { p in
                let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                if p.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    continuation.resume(throwing: UpdateError.processFailed(p.terminationStatus))
                }
            }
            do { try process.run() } catch { continuation.resume(throwing: error) }
        }
    }

    private func parseMountPoint(from plistXML: String) throws -> String {
        guard let data = plistXML.data(using: .utf8),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let entities = plist["system-entities"] as? [[String: Any]] else {
            throw UpdateError.mountFailed
        }
        for entity in entities {
            if let mountPoint = entity["mount-point"] as? String { return mountPoint }
        }
        throw UpdateError.mountFailed
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
}

// MARK: - Models

private struct GitHubRelease: Decodable {
    let tagName: String
    let htmlURL: String
    let assets: [ReleaseAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case assets
    }
}

private struct ReleaseAsset: Decodable {
    let name: String
    let browserDownloadURL: String

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
    }
}

private enum UpdateError: Error {
    case processFailed(Int32)
    case mountFailed
    case appNotFound
}
