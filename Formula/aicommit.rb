class Aicommit < Formula
    desc "AI powered Git commit messages"
    homepage "https://github.com/vsmash/aicommit"
    url "https://github.com/vsmash/aicommit/archive/refs/tags/4.8.22.tar.gz"
    sha256 "b686d5de97f239140bbdb6574469df8b787c638c48a6651f96bb5bdf403a8142"
    license "GPL-3.0-only"
    version "4.8.22"

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
