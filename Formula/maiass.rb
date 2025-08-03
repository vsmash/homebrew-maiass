class Maiass < Formula
    desc "Modular AI-Augmented Semantic Scribe for Git workflows"
    homepage "https://github.com/vsmash/maiass"
    url "https://github.com/vsmash/maiass/archive/refs/tags/5.5.10.tar.gz"
    sha256 "64ad51175d4993406066ea50bdc4563f675f35c754f61c5ab4551091da28ec83"
    license "GPL-3.0-only"
    version "5.5.10"

    depends_on "bash"
    depends_on "jq"

    def install
        bin.install "maiass.sh" => "maiass"
        bin.install "committhis.sh" => "committhis"
        bin.install "package.json"
        bin.install_symlink "maiass" => "myass"
        bin.install_symlink "maiass" => "miass"
        # Create a wrapper script that sets up the LIBEXEC_DIR
        (bin/"maiass").write <<~EOS
          #!/bin/bash
          export LIBEXEC_DIR="#{pkgshare}/lib"
          exec "#{libexec}/maiass" "$@"
        EOS

        # Make the wrapper executable
        chmod 0755, bin/"maiass"
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
