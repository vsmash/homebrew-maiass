class Maiass < Formula
  desc "Modular AI-Augmented Semantic Scribe for Git workflows"
  homepage "https://maiass.net"
  url "https://releases.maiass.net/bash/5.7.11/maiass-5.7.11.tar.gz"
  sha256 "896b2cca82bf05db26f28b00f90bfec14da1fb2f230e4f41fe6b5ac8571217ac"
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
    EOS
  end
end
