class Maiass < Formula
  desc "Modular AI-Augmented Semantic Scribe for Git workflows"
  homepage "https://maiass.net"
  url "https://github.com/vsmash/maiass/releases/download/v5.10.3/maiass-5.10.3.tar.gz"
  sha256 "ab30a66fd75bf05774bfe639cfdb5d8d51b5a18ec73a80cbb88555e544f417d2"
  license "GPL-3.0-only"
  version "5.10.3"

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
