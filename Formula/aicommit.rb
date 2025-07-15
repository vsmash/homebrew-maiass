class Aicommit < Formula
    desc "AI powered Git commit messages"
    homepage "https://github.com/vsmash/aicommit"
    url "https://github.com/vsmash/aicommit/archive/refs/tags/4.8.24.tar.gz"
    sha256 "9e853511797d35a0e775534842f716684b582e5c4a900f39e0aae7731755530a"
    license "GPL-3.0-only"
    version "4.8.24"

    depends_on "bash"
    depends_on "jq"

    def install
        bin.install "maiass.sh" => "maiass"
        bin.install "aicommit.sh" => "aicommit"
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
