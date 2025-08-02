class Maiass < Formula
  desc "MAIASS: Modular AI-Augmented Semantic Scribe - CLI tool for AI-augmented development"
  homepage "https://github.com/vsmash/maiass"
  url "https://github.com/vsmash/maiass/archive/refs/tags/#{version}.tar.gz"
  version "5.2.9"

  license "GPL-3.0-only"
  on_macos do
    if Hardware::CPU.intel?
      url "https://github.com/vsmash/maiass/releases/download/#{version}/maiass-macos-intel"
      sha256 "dee85c7187534da2c15cfa379e35da1144c1ddf4a25ce93766eb3c6fa4e18da3"
    else
      url "https://github.com/vsmash/maiass/releases/download/#{version}/maiass-macos-arm64"
      sha256 "54866706a8cf77511695b4ca2ffdff10de14743e2212a4d6d093d82b7325fde3"
    end
  end

  on_linux do
    url "https://github.com/vsmash/maiass/releases/download/#{version}/maiass-linux-x64"
    sha256 "85e7ba47d65bad2e07f526e00171a0eaa897088306d678ed2fa1fb7adc8a39f5"
  end

  def install
    bin.install Dir["maiass-*"].first => "maiass"
    bin.install_symlink "maiass" => "myass"
    bin.install_symlink "maiass" => "miass"

  end

  test do
    system "#{bin}/maiass", "--version"
    system "#{bin}/maiass", "--help"
  end
end
