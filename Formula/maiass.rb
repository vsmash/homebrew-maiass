class Maiass < Formula
  desc "Modular AI-Augmented Semantic Scribe for Git workflows"
  homepage "https://maiass.net"
  url "https://releases.maiass.net/bash/5.7.1/bashmaiass-5.7.1.tar.gz"
  sha256 "1a46c56ae14d77e652b7466ea7702386084b02c8f7d57c9118d942f03284da93"
  license "GPL-3.0-only"
  version "5.7.1"
  
  depends_on "bash"
  depends_on "jq"

  def install
    bin.install "maiass.sh" => "maiass"
    bin.install "bundle.sh" => "committhis"
    libexec.install "lib"
    
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
