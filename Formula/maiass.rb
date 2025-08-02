class Maiass < Formula
  desc "MAIASS: Modular AI-Augmented Semantic Scribe - CLI tool for AI-augmented development"
  homepage "https://github.com/vsmash/maiass"
  url "https://github.com/vsmash/maiass/archive/refs/tags/#{version}.tar.gz"
  version "5.3.6"

  license "GPL-3.0-only"
  on_macos do
    if Hardware::CPU.intel?
      url "https://github.com/vsmash/maiass/releases/download/#{version}/maiass-macos-x64.zip"
      sha256 "383ca3c9bd8f2c027fe8be9004d0400691ba8fce640718a3771f0e812e7ca350"
    else
      url "https://github.com/vsmash/maiass/releases/download/#{version}/maiass-macos-arm64.zip"
      sha256 "09a677ee3ba1d3de98b12f223ec826ed4315875b995c8a70b4be80832fed1ed0"
    end
  end

  on_linux do
    url "https://github.com/vsmash/maiass/releases/download/#{version}/maiass-linux-x64.tar.gz"
    sha256 "add005ffb04fd9439d7c83e1725284b186ab99afebcc4345f0f698259e2c55a3"
  end

  def install
    # Extract the binary from the archive and install it
    if OS.mac?
      bin.install Dir["maiass-macos-*"].first => "maiass"
    elsif OS.linux?
      bin.install Dir["maiass-linux-*"].first => "maiass"
    end
    
    # Create convenience symlinks
    bin.install_symlink "maiass" => "myass"
    bin.install_symlink "maiass" => "miass"
  end

  test do
    system "#{bin}/maiass", "--version"
    system "#{bin}/maiass", "--help"
  end
end
