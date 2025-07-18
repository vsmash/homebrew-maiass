class Committhis < Formula
    desc "AI powered Git commit messages"
    homepage "https://github.com/vsmash/committhis"
    url "https://github.com/vsmash/committhis/archive/refs/tags/4.10.15.tar.gz"
    sha256 "bcd43cfb9310cd59445029591d66cf98bd5e4f64f6068c556ea9672bcc390605"
    license "GPL-3.0-only"
    version "4.10.15"
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
