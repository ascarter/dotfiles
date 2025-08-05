class SkLibfido2 < Formula
  desc "Standalone security key library for OpenSSH YubiKey SSH resident keys"
  homepage "https://www.openssh.com/"
  url "https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-10.0p2.tar.gz"
  mirror "https://cloudflare.cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-10.10p2.tar.gz"
  version "10.0p2"
  sha256 "021a2e709a0edf4250b1256bd5a9e500411a90dddabea830ed59cef90eb9d85c"
  license "SSH-OpenSSH"

  livecheck do
    url "https://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/"
    regex(/href=.*?openssh[._-]v?(\d+(?:\.\d+)+(?:p\d+)?)\.t/i)
  end

  depends_on "pkgconf" => :build
  depends_on "libfido2"
  depends_on "openssl@3"

  uses_from_macos "zlib"

  def install
    # Configure OpenSSH with minimal dependencies needed for security key support
    args = %W[
      --prefix=#{prefix}
      --with-security-key-standalone
    ]

    system "./configure", *args

    # Build only the components we need for the standalone security key library
    system "make", "sk-libfido2.#{shared_library_extension}"

    # Install the standalone library
    lib.install "sk-libfido2.#{shared_library_extension}"
  end

  def caveats
    <<~EOS
      This formula installs only the standalone security key library for OpenSSH.

      To use YubiKey SSH resident keys with OpenSSH, you need:
      1. OpenSSH 8.2+ (install via 'brew install openssh' if needed)
      2. This library installed at: #{lib}/sk-libfido2.#{shared_library_extension}
      3. Set the SSH_SK_PROVIDER environment variable

      Add this to your shell profile (~/.zshrc, ~/.bashrc, etc.):
        export SSH_SK_PROVIDER=#{lib}/sk-libfido2.#{shared_library_extension}

      Alternately, set provider in ~/.ssh/config:
        SecurityKeyProvider #{lib}/sk-libfido2.#{shared_library_extension}

      The library will be automatically discovered by OpenSSH's ssh-keygen and
      ssh-add commands when generating or using FIDO2/U2F keys.

      To generate a resident key:
        ssh-keygen -t ecdsa-sk -O resident -f ~/.ssh/id_ecdsa_sk

      To load resident keys from your YubiKey:
        ssh-add -K
    EOS
  end

  test do
    # Test that the library exists and is a proper shared library
    assert_predicate lib/"sk-libfido2.#{shared_library_extension}", :exist?

    if OS.mac?
      assert_match "Mach-O", shell_output("file #{lib}/sk-libfido2.dylib")
      # Test symlink exists on macOS
      assert_predicate lib/"sk-libfido2.so", :exist?
    else
      assert_match "ELF", shell_output("file #{lib}/sk-libfido2.so")
    end

    # Test that required symbols are exported (use nm or objdump depending on platform)
    nm_cmd = OS.mac? ? "nm" : "nm -D"
    output = shell_output("#{nm_cmd} #{lib}/sk-libfido2.#{shared_library_extension} 2>/dev/null || nm #{lib}/sk-libfido2.#{shared_library_extension}")

    %w[sk_api_version sk_enroll sk_sign sk_load_resident_keys].each do |symbol|
      assert_match symbol, output, "Required symbol #{symbol} not found in library"
    end
  end

  private

  def shared_library_extension
    OS.mac? ? "dylib" : "so"
  end
end
