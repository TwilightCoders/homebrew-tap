# Slang shading-language compiler (slangc) + tooling, from the OFFICIAL
# shader-slang/slang prebuilt releases. Packaged as a CASK, not a formula, on
# purpose: a formula ad-hoc re-signs Mach-O on Apple Silicon, which strips the
# upstream Team ID off the bundled dylibs and leaves them mismatched against the
# executables (dyld then refuses to load them). A cask places the binaries
# UNTOUCHED — the release is already self-consistent (@rpath-relocatable, every
# binary + dylib signed Team ID TD2656HYNK) — so slangc just runs.
#
#   brew install twilightcoders/tap/slang
cask "slang" do
  arch arm: "aarch64", intel: "x86_64"

  version "2026.11"
  sha256 arm:   "29f50cb3d6b51e9c4458fe9c717f5ea387863946c56d8e81d925b12f904aef7f",
         intel: "3bb7d7be3ce7fbf54df4785105147b6c4fd3bfcef53349c77584ca89e360f13a"

  url "https://github.com/shader-slang/slang/releases/download/v#{version}/slang-#{version}-macos-#{arch}.tar.gz"
  name "Slang"
  desc "Shader compiler (slangc) and tooling for the Slang shading language"
  homepage "https://github.com/shader-slang/slang"

  # Lets `brew livecheck` spot new upstream releases and `brew bump-cask-pr`
  # auto-fill the version + every arch's sha256.
  livecheck do
    url :url
    strategy :github_latest
  end

  # bin/ and its sibling lib/ both land in the Caskroom; the symlink's
  # @loader_path resolves back to the real bin, so `../lib` finds libslang*.dylib.
  binary "bin/slangc"
  binary "bin/slangd"
  binary "bin/slangi"

  zap trash: "~/Library/Caches/slang"
end
