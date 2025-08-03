class Miass < Formula
    desc "Alias for MAIASS"
    homepage "https://github.com/vsmash/maiass"
    url "https://github.com/vsmash/maiass/archive/refs/tags/4.14.1.tar.gz"
    sha256 "8b0a25dbfb7cb2acf5699c419a1804c15c0a3992ad7fb1549aaccb5523a618fd"
    license "GPL-3.0-only"
    version "4.14.1"

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
