class Maiass < Formula
  desc "MAIASS: Modular AI-Augmented Semantic Scribe - CLI tool for AI-augmented development"
  homepage "https://github.com/vsmash/maiass"
  url "https://github.com/vsmash/maiass/archive/refs/tags/#{version}.tar.gz"
  version "5.3.2"

  license "GPL-3.0-only"
  on_macos do
    if Hardware::CPU.intel?
      url "https://github.com/vsmash/maiass/releases/download/#{version}/maiass-macos-intel"
      sha256 "f39bc46fd19acb95456e14cb0391d595f5068569659f25c2a19391f3871b6104"
    else
      url "https://github.com/vsmash/maiass/releases/download/#{version}/maiass-macos-arm64"
      sha256 "67e368f682f0122433cbea623f2fc53652584b8e81357fc2f661419b9291fcac"
    end
  end

  on_linux do
    url "https://github.com/vsmash/maiass/releases/download/#{version}/maiass-linux-x64"
    sha256 "f29c735325bd00f6776dfecad8e18bf8c6e8da16a0f1417b2e94e60f4eb5a720"
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
