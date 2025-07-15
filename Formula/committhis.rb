class Committhis < Formula
    desc "AI powered Git commit messages"
    homepage "https://github.com/vsmash/committhis"
    url "https://github.com/vsmash/committhis/archive/refs/tags/4.8.32.tar.gz"
    sha256 "af70c76ebc98c29716291a3bcada44bb259373998727ea4d72274b2525212e09"
    license "GPL-3.0-only"
    version "4.8.32"

    depends_on "bash"
    depends_on "jq"

    def install
        bin.install "maiass.sh" => "maiass"
        bin.install "committhis.sh" => "committhis"
        bin.install "package.json"
        bin.install_symlink "committhis" => "aic"
        bin.install_symlink "maiass" => "myass"
        bin.install_symlink "maiass" => "miass"
    end

    test do
      assert_match "MAIASS", shell_output("#{bin}/maiass --help")
    end
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
        export MAIASS_OPENAI_TOKEN=your_api_key
        export MAIASS_OPENAI_MODE=ask

      Full docs: https://github.com/vsmash/maiass
    EOS
  end
