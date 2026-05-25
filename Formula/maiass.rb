class Maiass < Formula
  desc "Modular AI-Augmented Semantic Scribe for Git workflows"
  homepage "https://maiass.net"
  url "https://github.com/vsmash/maiass/releases/download/v5.10.56/maiass-5.10.56.tar.gz"
  sha256 "6bf72a2c846699c855671794fc00aa3594c5b3d6b536b8518563723917e73002"
  license "GPL-3.0-only"
  version "5.10.56"
  
  depends_on "bash"
  depends_on "jq"

  def install
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
