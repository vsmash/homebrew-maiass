class Maiass < Formula
  desc "MAIASS: Modular AI-Augmented Semantic Scribe - CLI tool for AI-augmented development"
  homepage "https://github.com/vsmash/maiass"
  url "https://github.com/vsmash/maiass/archive/refs/tags/#{version}.tar.gz"
  version "5.2.8"

  license "GPL-3.0-only"
  on_macos do
    if Hardware::CPU.intel?
      url "https://github.com/vsmash/maiass/releases/download/#{version}/maiass-macos-intel"
      sha256 "f9f9f4f4ff8deb626c81b3906628b8a802a5d05da9e64581fbc9bbbebaa2cc81"
    else
      url "https://github.com/vsmash/maiass/releases/download/#{version}/maiass-macos-arm64"
      sha256 "ed3ba7b044e0a235ce653a9c7da840a8e131f1873bff60aac7d2b309a2ebbfa7"
    end
  end

  on_linux do
    url "https://github.com/vsmash/maiass/releases/download/#{version}/maiass-linux-x64"
    sha256 "778692224f3de1af511dc9582ed1d42d1deae855b87696f8b2b5927298aa07a0"
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
