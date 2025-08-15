class Maiass < Formula
  desc "Modular AI-Augmented Semantic Scribe for Git workflows"
  homepage "https://maiass.net"
  url "https://releases.maiass.net/bash/5.7.11/maiass-5.7.11.tar.gz"
  sha256 "9c783ad282f9bb45ba30226d50b9fc5ddc115832a44548e22139ed4d12796a44"
  license "GPL-3.0-only"
  version "5.7.11"
  
  depends_on "bash"
  depends_on "jq"

  def install
    bin.install "maiass.sh" => "maiass"
    
    # Install lib directory if it exists
    if File.exist?("lib")
      libexec.install "lib"
    end
    
    # Create symlinks for convenience
    bin.install_symlink "maiass" => "myass"
    bin.install_symlink "maiass" => "miass"
  end

  test do
    assert_match "MAIASS", shell_output("#{bin}/maiass --version")
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

      Full docs: https://maiass.net
      
      Note: If you have a global npm version of maiass, the Homebrew version
      will take precedence in your PATH. To remove the npm version, run:
      npm uninstall -g maiass
    EOS
  end
end
