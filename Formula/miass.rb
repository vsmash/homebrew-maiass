class Miass < Formula
    desc "Alias for MAIASS"
    homepage "https://github.com/vsmash/maiass"
    url "https://github.com/vsmash/maiass/archive/refs/tags/4.11.2.tar.gz"
    sha256 "037c97afef2d987fc3b15a18d40039a8b7304d7b6eb5813eb7dd210bdce00019"
    license "GPL-3.0-only"
    version "4.11.2"

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
