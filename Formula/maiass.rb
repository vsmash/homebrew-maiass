class Maiass < Formula
    desc "Modular AI-Augmented Semantic Scribe for Git workflows"
    homepage "https://github.com/vsmash/maiass"
    url "https://github.com/vsmash/maiass/archive/refs/tags/5.5.11.tar.gz"
    sha256 "2d3c54cf4e0b3e3536c1c17a0e422e16be8a737552410f30ffcbbdb074b38c65"
    license "GPL-3.0-only"
    version "5.5.11"

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
        export MAIASS_AI_TOKEN=your_api_key
        export MAIASS_AI_MODE=ask

      Full docs: https://github.com/vsmash/bashmaiass
    EOS
  end
