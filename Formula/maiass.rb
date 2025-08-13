class Maiass < Formula
    desc "Modular AI-Augmented Semantic Scribe for Git workflows"
    homepage "https://github.com/vsmash/maiass"
    url "https://github.com/vsmash/maiass/archive/refs/tags/5.6.28.tar.gz"
    sha256 "7a2da5ff227c679c64e70374486b40e0f8b31d65a2b182e41513b695f6d3223e"
    license "GPL-3.0-only"
    version "5.6.28"
    conflicts_with "committhis", because: "both install overlapping binaries"

    depends_on "bash"
    depends_on "jq"

    def install
        bin.install "maiass.sh" => "maiass"
        bin.install "committhis.sh" => "committhis"
        bin.install "package.json"
        bin.install_symlink "maiass" => "myass"
        bin.install_symlink "maiass" => "miass"
        libexec.install "lib"
        # Create a wrapper script that sets up the LIBEXEC_DIR
    end


    # Make the wrapper executable
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
