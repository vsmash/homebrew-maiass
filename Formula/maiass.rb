class Maiass < Formula
  desc "MAIASS: Modular AI-Augmented Semantic Scribe - CLI tool for AI-augmented development"
  homepage "https://github.com/vsmash/maiass"
  url "https://github.com/vsmash/maiass/archive/refs/tags/#{version}.tar.gz"
  version "5.3.6"

  license "GPL-3.0-only"
  on_macos do
    if Hardware::CPU.intel?
      url "https://github.com/vsmash/maiass/releases/download/#{version}/maiass-macos-x64.zip"
      sha256 "20595b682b1804f335100adfa95e7b442785ee9d7a61f403baadf08964197916"
    else
      url "https://github.com/vsmash/maiass/releases/download/#{version}/maiass-macos-arm64.zip"
      sha256 "901feb3554dafeb4a5381ee5f067bcd612c1ffbb655fd1415c5e0152397e2c64"
    end
  end

  on_linux do
    url "https://github.com/vsmash/maiass/releases/download/#{version}/maiass-linux-x64.tar.gz"
    sha256 "882eb096f0b1c6a97ff7d6b9b9e1c91a54e0577f695ce6740d4fa2b0dd4e89d3"
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
