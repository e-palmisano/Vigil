cask "vigil" do
  version "1.0.0"
  sha256 "REPLACE_WITH_SHA256_FROM_RELEASE"

  url "https://github.com/YOUR_GITHUB_USERNAME/vigil/releases/download/v#{version}/Vigil-#{version}.dmg"
  name "Vigil"
  desc "System-wide input lock for macOS — keep workloads running while locked"
  homepage "https://github.com/YOUR_GITHUB_USERNAME/vigil"

  depends_on macos: ">= :sequoia"

  app "Vigil.app"

  postflight do
    system_command "/usr/bin/open",
      args: ["-a", "Vigil"],
      sudo: false
  end

  zap trash: [
    "~/Library/Preferences/com.yourname.vigil.plist",
    "~/Library/Application Support/Vigil",
  ]
end
