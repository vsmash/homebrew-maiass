class Committhis < Formula
    desc "AI powered Git commit messages"
    homepage "https://github.com/vsmash/committhis"
    url "https://github.com/vsmash/committhis/archive/refs/tags/4.10.11.tar.gz"
    sha256 "888d11d022193c748b9cabaa5270ccc9953222ecb38e5db5b9b1dfe853386701"
    license "GPL-3.0-only"
    version "4.10.11"
    conflicts_with "maiass", because: "both install overlapping binaries"

    depends_on "bash"
    depends_on "jq"

    def install
        bin.install "maiass.sh" => "maiass"
        bin.install "committhis.sh" => "committhis"
        bin.install_symlink "committhis" => "aic"
        bin.install_symlink "maiass" => "myass"
        bin.install_symlink "maiass" => "miass"
    end

    test do
      assert_match "COMMITTHIS", shell_output("#{bin}/committhis --help")
    end
  end

  def caveats
    <<~EOS
      🧠 MAIASS has been installed!

      You can now use:
        committhis       # Main command
        aic # Shortcut aliases

      To view usage:
        maiass --help

      To enable AI commit messages:
        export MAIASS_OPENAI_TOKEN=your_api_key
        export MAIASS_OPENAI_MODE=ask

      Full docs: https://github.com/vsmash/maiass
    EOS
  end
