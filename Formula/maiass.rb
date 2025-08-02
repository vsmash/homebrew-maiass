class Maiass < Formula
  desc "MAIASS: Modular AI-Augmented Semantic Scribe - CLI tool for AI-augmented development"
  homepage "https://github.com/vsmash/maiass"
  url "https://github.com/vsmash/maiass/archive/refs/tags/#{version}.tar.gz"
  version "5.3.3"

  license "GPL-3.0-only"
  on_macos do
    if Hardware::CPU.intel?
      url "https://github.com/vsmash/maiass/releases/download/#{version}/maiass-macos-x64"
      sha256 "a559b88904aa2139abc78a5dc72b05291999811ca5f894a0e2c6e348765951bb"
    else
      url "https://github.com/vsmash/maiass/releases/download/#{version}/maiass-macos-arm64"
      sha256 "c13bc0548d803a0243c5b763aca1630c588822b24957291cfa72121b2c86be18"
    end
  end

  on_linux do
    url "https://github.com/vsmash/maiass/releases/download/#{version}/maiass-linux-x64"
    sha256 "fbf64d4fa4c87037e90b81c900970cd5314406636b4c3cce9d26a7104cabf80a"
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
