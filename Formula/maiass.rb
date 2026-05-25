class Maiass < Formula
  desc "Modular AI-Augmented Semantic Scribe for Git workflows"
  homepage "https://maiass.net"
  url "https://github.com/vsmash/maiass/releases/download/v5.10.55/maiass-5.10.55.tar.gz"
  sha256 "0b4a8c320f32dc93b6d2d23715f23db5f706db758b5ae869e71aeccebd229b7f"
  license "GPL-3.0-only"
  version "5.10.55"
  
  depends_on "bash"
  depends_on "jq"

  def install
    bin.install "maiass.sh" => "maiass"
    bin.install "committhis.sh" => "committhis"
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
