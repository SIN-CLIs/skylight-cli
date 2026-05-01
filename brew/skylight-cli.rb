class SkylightCli < Formula
  desc "Invisible macOS UI automation via AXPress (ACT layer of Stealth-Triade)"
  homepage "https://github.com/SIN-CLIs/skylight-cli"
  url "https://github.com/SIN-CLIs/skylight-cli/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "PLACEHOLDER"
  license "MIT"; version "0.2.0"
  depends_on xcode: ["16.2"]
  def install
    system "swift", "build", "-c", "release", "-Xlinker", "-F/System/Library/PrivateFrameworks"
    bin.install ".build/release/skylight" => "skylight-cli"
  end
  test do
    assert_match "0.2.0", shell_output("#{bin}/skylight 2>&1 || true")
  end
end
