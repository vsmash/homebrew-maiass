class Committhis < Formula
    desc "AI powered Git commit messages"
    homepage "https://github.com/vsmash/committhis"
    url "https://github.com/vsmash/committhis/archive/refs/tags/5.6.28.tar.gz"
    sha256 "0c98a3808eecc684567fabc418a717caaf59726b7d2445f4d53feac14dd59dac"
    license "GPL-3.0-only"
    version "5.6.28"
    conflicts_with "maiass", because: "both install overlapping binaries"

    depends_on "bash"
    depends_on "jq"

    def install
        bin.install "maiass.sh" => "maiass"
        bin.install "committhis.sh" => "committhis"
        bin.install "package.json"
        libexec.install "lib"
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
        export MAIASS_AI_TOKEN=your_api_key
        export MAIASS_AI_MODE=ask

      Full docs: https://github.com/vsmash/maiass
    EOS
  end
