class Miass < Formula
    desc "Alias for MAIASS"
    homepage "https://github.com/vsmash/maiass"
    url "https://github.com/vsmash/bashmaiass/archive/refs/tags/4.14.0.tar.gz"
    sha256 "ef11ad9c6f283b322925676a2a3706cd5c4b3b1118da580a1a6489063413b490"
    license "GPL-3.0-only"
    version "4.14.0"

    depends_on "bash"
    depends_on "jq"

    def install
      bin.install "maiass.sh" => "maiass"
      bin.install "committhis.sh" => "committhis"
      bin.install "package.json"
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
