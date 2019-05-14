class SnipsInjection < Formula
  desc "Snips Words Injection"
  homepage "https://snips.ai"

  url "ssh://git@github.com/snipsco/snips-platform.git",
    :using => :git, :tag => "0.63.2", :revision => "ad2da891177f1f41da3f767a5346e6e063839653"

  head "ssh://git@github.com/snipsco/snips-platform.git",
    :using => :git, :branch => "develop"

  bottle do
    root_url "https://homebrew.snips.ai/bottles"
    cellar :any_skip_relocation
    sha256 "dbc8f2c68bae9016917f596d00347323c7455677ec64d33b3601f002e5c84225" => :el_capitan
  end

  option "with-debug", "Build with debug support"
  option "without-completion", "bash, zsh and fish completion will not be installed"

  depends_on "autoconf" => :build # needed by snips-fst-rs
  depends_on "automake" => :build # needed by snips-fst-rs
  depends_on "pkg-config" => :build # needed by snips-kaldi
  depends_on "rust" => :build
  depends_on "snips-platform-common"

  def install
    target_dir = build.with?("debug") ? "target/debug" : "target/release"

    args = %W[--root=#{prefix}]
    args << "--path=snips-injection/snips-injection"
    args << "--debug" if build.with? "debug"

    # Needed to build openfst (cstdint issue)
    ENV["MACOSX_DEPLOYMENT_TARGET"] = "10.11"

    system "cargo", "install", *args

    bin.install "#{target_dir}/snips-injection"

    mkdir_p "homebrew/snips"
    cp_r "snips-asr/snips-g2p-resources", "homebrew/snips/g2p-models"
    share.install "homebrew/snips"

    if build.with? "completion"
      bash_completion.install "#{target_dir}/completion/snips-injection.bash"
      fish_completion.install "#{target_dir}/completion/snips-injection.fish"
      zsh_completion.install "#{target_dir}/completion/_snips-injection"
    end
  end

  plist_options :manual => "snips-injection -c #{HOMEBREW_PREFIX}/etc/snips.toml"

  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>KeepAlive</key>
        <dict>
          <key>SuccessfulExit</key>
          <false/>
        </dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{opt_bin}/snips-injection</string>
          <string>-c</string>
          <string>#{etc}/snips.toml</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>WorkingDirectory</key>
        <string>#{var}</string>
        <key>StandardErrorPath</key>
        <string>#{var}/log/snips/snips-injection.log</string>
        <key>StandardOutPath</key>
        <string>#{var}/log/snips/snips-injection.log</string>
        <key>ProcessType</key>
        <string>Interactive</string>
      </dict>
    </plist>
  EOS
  end

  test do
    assert_equal "snips-injection #{version}\n", shell_output("#{bin}/snips-injection --version")
  end
end
