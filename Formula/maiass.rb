class Maiass < Formula
  desc "Modular AI-Augmented Semantic Scribe for Git workflows"
  homepage "https://maiass.net"
  url "https://github.com/vsmash/maiass/releases/download/v5.10.61/maiass-5.10.61.tar.gz"
  sha256 "bf8e4845b95f03a489439b07f74c1cdd641fc95047d269037de2bcf86036ecd0"
  license "GPL-3.0-only"
  version "5.10.61"
  
  depends_on "bash"
  depends_on "jq"

  def install
    # The release tarball ships two self-contained bundles (no lib/ — each is a
    # single bundled script) plus committhis as committhis.sh.
    bin.install "maiass.sh" => "maiass"
    bin.install "committhis.sh" => "committhis"

    # Create symlinks for convenience
    bin.install_symlink "maiass" => "myass"
    bin.install_symlink "maiass" => "miass"
  end

  test do
    assert_match "MAIASS", shell_output("#{bin}/maiass --version")
  end

  def caveats
    <<~EOS
      🧠 MAIASS has been installed!

      You can now use:
        maiass       # Main command
        myass, miass # Shortcut aliases

      To view usage:
        maiass --help

      To enable AI commit messages:
        export MAIASS_AI_TOKEN=your_api_key
        export MAIASS_AI_MODE=ask

      Full docs: https://maiass.net
    EOS
  end
end
