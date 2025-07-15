class Aicommit < Formula
    desc "AI powered Git commit messages"
    homepage "https://github.com/vsmash/aicommit"
    url "https://github.com/vsmash/aicommit/archive/refs/tags/4.8.28.tar.gz"
    sha256 "0ac8ba9409777338e3618975a049df29280be7ed17196c8df4376589921e417c"
    license "GPL-3.0-only"
    version "4.8.28"

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
