class Maiass < Formula
    desc "Modular AI-Assisted Semantic Sidekick for Git workflows"
    homepage "https://github.com/vsmash/maiass"
    url "https://github.com/vsmash/maiass/archive/refs/tags/v4.5.0.tar.gz"
    sha256 "d5558cd419c8d46bdc958064cb97f963d1ea793866414c025906ec15033512ed"
    license "MIT"
    version "4.5.0"
  
    depends_on "bash"
    depends_on "jq"
  
    def install
        bin.install "maiass.sh" => "maiass"
        bin.install_symlink "maiass" => "myass"
        bin.install_symlink "maiass" => "miass"
    end
  
    test do
      assert_match "MAIASS", shell_output("#{bin}/maiass --help")
    end
  end
  