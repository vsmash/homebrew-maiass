class Miass < Formula
    desc "Alias for MAIASS"
    homepage "https://github.com/vsmash/maiass"
    url "https://github.com/vsmash/maiass/archive/refs/tags/4.8.3.tar.gz"
    sha256 "9a44bc35c9758334c9d13618fe9637f0668c50e9ec8692f6e7dc65782ec568d6"
    license "GPL-3.0-only"
    version "4.8.3"
  
    depends_on "bash"
    depends_on "jq"
  
    def install
      bin.install "maiass.sh" => "maiass"
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