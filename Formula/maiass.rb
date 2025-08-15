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
    # Check for existing maiass installation
    check_existing_installation
    
    bin.install "maiass.sh" => "maiass"
    
    # Install lib directory if it exists
    if File.exist?("lib")
      libexec.install "lib"
    end
    
    # Create symlinks for convenience
    bin.install_symlink "maiass" => "myass"
    bin.install_symlink "maiass" => "miass"
  end

  def check_existing_installation
    # Check for global npm installation
    npm_maiass_path = nil
    begin
      npm_maiass_path = `which maiass 2>/dev/null`.strip
      if !npm_maiass_path.empty? && (npm_maiass_path.include?("/node_modules/") || npm_maiass_path.include?("/npm/"))
        puts "⚠️  Warning: maiass is already installed globally via npm"
        puts "   Path: #{npm_maiass_path}"
        puts
        puts "Options:"
        puts "1. Remove global npm version: npm uninstall -g maiass"
        puts "2. Continue installation (may cause conflicts)"
        puts "3. Cancel installation"
        puts
        print "Choose option (1-3): "
        choice = STDIN.gets.chomp
        
        case choice
        when "1"
          puts "Removing global npm version..."
          system("npm", "uninstall", "-g", "maiass")
          puts "✅ Global npm version removed"
        when "2"
          puts "⚠️  Continuing installation - conflicts may occur"
        when "3"
          puts "❌ Installation cancelled"
          exit 1
        else
          puts "❌ Invalid choice, installation cancelled"
          exit 1
        end
      end
    rescue => e
      # Ignore errors, continue with installation
    end
    
    # Check for existing symlinks that might conflict
    ["myass", "miass"].each do |symlink|
      if File.exist?("#{HOMEBREW_PREFIX}/bin/#{symlink}")
        puts "⚠️  Warning: #{symlink} symlink already exists"
        puts "   This will be replaced by the Homebrew installation."
      end
    end
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
      
      Note: If you had a global npm version of maiass, it has been replaced.
      The Homebrew version takes precedence in your PATH.
    EOS
  end
end
