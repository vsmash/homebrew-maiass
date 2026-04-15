class Maiass < Formula
  desc "Modular AI-Augmented Semantic Scribe for Git workflows"
  homepage "https://maiass.net"
  url "https://releases.maiass.net/bash/5.10.53/bashmaiass-5.10.53.tar.gz"
  sha256 "c847419f5b08b67e9d80663a885c543a9063c922f9a839cd87d6966ef05811c8"
  license "GPL-3.0-only"
  version "5.10.53"
  
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
