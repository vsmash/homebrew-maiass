class Maiass < Formula
  desc "Modular AI-Augmented Semantic Scribe for Git workflows"
  homepage "https://maiass.net"
  url "https://github.com/vsmash/maiass/releases/download/v5.10.18/maiass-5.10.18.tar.gz"
  sha256 "518e41a12f12392943af0ad356c09a3ff30c6b4c8a5daf6570f70cd6dc571648"
  license "GPL-3.0-only"
  version "5.10.18"

  depends_on "bash"
  depends_on "jq"

  def install
    bin.install "maiass.sh" => "maiass"

    # Install lib directory if it exists
    if File.exist?("lib")
      libexec.install "lib"
    end

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

      Full docs: https://maiass.net

      Note: If you have a global npm version of maiass, the Homebrew version
      will take precedence in your PATH.
      To remove the npm version, run:
      npm uninstall -g maiass
      To keep both versions, you can use the following alias:
      myass, miass
    EOS
  end
end
