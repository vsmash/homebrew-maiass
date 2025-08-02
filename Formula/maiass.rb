class Maiass < Formula
  desc "MAIASS: Modular AI-Augmented Semantic Scribe - CLI tool for AI-augmented development"
  homepage "https://github.com/vsmash/maiass"
  url "https://github.com/vsmash/maiass/archive/refs/tags/#{version}.tar.gz"
  version "5.3.0"

  license "GPL-3.0-only"
  on_macos do
    if Hardware::CPU.intel?
      url "https://github.com/vsmash/maiass/releases/download/#{version}/maiass-macos-intel"
      sha256 "c405e4fdb9c08354020d22d80878c1dab7ed4aa2a778daecad912503460681cc"
    else
      url "https://github.com/vsmash/maiass/releases/download/#{version}/maiass-macos-arm64"
      sha256 "b1fd0ec6138d4a0b0d65726e38a417a59a64d5ef5025a35b93828991e45ad4c5"
    end
  end

  on_linux do
    url "https://github.com/vsmash/maiass/releases/download/#{version}/maiass-linux-x64"
    sha256 "c41fc3912814a175a6ce0ca96a6becfc6c24fb7b930f5cb75eb044bdb7a50a25"
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
