class Myass < Formula
    desc "Alias for MAIASS"
    homepage "https://github.com/vsmash/maiass"
    url "https://github.com/vsmash/maiass/archive/refs/tags/4.5.1.tar.gz"
    sha256 "1aa054b0ae0374774227d613666b276f166f08e0fbe91caf0b5e76c1ddb44cc3"
    license "GPL-3.0-only"
    version "4.5.1"
  
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
  