# Development on Fedora Atomic (Cosmic Spin)

This document outlines how to set up and use **Fedora Atomic (Cosmic spin)** on a Framework 13 laptop for software development. It assumes a workflow centered around **toolbox containers** for builds, with **Linux Homebrew in its default location** to manage user-level CLI tools and language runtimes.

---

## 1. Philosophy

Fedora Atomic is an **immutable OS**. The base system (`/usr`) is managed by rpm-ostree. To keep the host clean and stable:

- **Layer minimally**: only system services or host-only tools.  
- **Flatpak for desktop apps**: browsers, chat, productivity, media.  
- **Toolbox for development**: mutable containers with compilers and headers.  
- **Homebrew in `/home/linuxbrew/.linuxbrew`**: a shared toolchain and CLI manager, available to both host and toolboxes.  

---

## 2. Host Setup

### Layered with rpm-ostree
Minimal layering for core services:

```bash
rpm-ostree install tailscale btop podman toolbox git gh zsh
```

- **tailscale**: VPN daemon.  
- **btop**: system monitor.  
- **podman/toolbox**: containerized environments.  
- **git/gh**: lightweight git support.  
- **zsh**: preferred shell (optional).  

### Desktop apps (Flatpak/AppImage)
- Proton apps (Mail, Pass, Authenticator, VPN).  
- Signal, Spotify, Vivaldi, Chromium (Flatpak).  
- Chrome (AppImage or RPM for testing).  
- Zed, Helix, Ghostty, VS Code (Flatpak or `~/.local/bin`).  
- Apple Music: via web or Cider (Flatpak).  

---

## 3. Homebrew

Install Homebrew to the default location:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

This creates `/home/linuxbrew/.linuxbrew`. Add to your shell:

```bash
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zshrc
```

### What to install with Homebrew
- **Language managers**: rustup, rbenv, go (via tarball or brew).  
- **CLI tools**: ripgrep, fd, bat, gh, just, kubectl, age, chezmoi, etc.  
- **LSPs**: rust-analyzer, gopls, solargraph.  

> ⚠️ Avoid using Brew for system libraries (`openssl`, `zlib`, etc.). Use Fedora `-devel` packages inside toolbox for builds.

---

## 4. Toolbox Strategy

### Creating a dev toolbox
Bind-mount `/home/linuxbrew` into the toolbox so the shared Homebrew tree is visible:

```bash
toolbox create --container dev-f42 --release f42   --volume /home/linuxbrew:/home/linuxbrew:rw,Z
toolbox enter dev-f42
```

- `:Z` applies SELinux relabeling so the container can read/write.  
- Inside the toolbox, `brew` is available because `/home/linuxbrew/.linuxbrew` is mounted and `$PATH` comes from your shell config.  

### Build dependencies
Install system headers and compilers (one-time inside toolbox):

```bash
sudo dnf install -y   gcc gcc-c++ make pkgconf pkgconf-pkg-config   autoconf bison patch   openssl-devel zlib-devel readline-devel libyaml-devel   libffi-devel gdbm-devel ncurses-devel libxml2-devel libxslt-devel   bzip2-devel sqlite-devel
```

---

## 5. Toolchains via Homebrew

With `/home/linuxbrew` mounted, install runtimes globally in Brew. They’ll live once and work in both host and toolbox.

### Rust
```bash
brew install rustup-init
rustup-init -y
rustup component add rust-src rust-analyzer
```

### Ruby
```bash
brew install rbenv ruby-build
rbenv install 3.3.4
rbenv global 3.3.4
gem install bundler rake
```

### Go
```bash
brew install go
```

Configure environment (in `~/.zshrc`):

```bash
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
```

---

## 6. Editors & LSPs

- **Editors (host)**: Run Zed, Helix, VS Code as Flatpaks or binaries in `~/.local/bin`. They’ll use LSPs installed via Homebrew (`~/.linuxbrew/bin`).  
- **Editors (toolbox)**: Run inside toolbox for maximum build parity.  
- **LSPs**: Install via Homebrew or language managers; they live in `/home/linuxbrew/.linuxbrew/bin` and are shared across environments.  

---

## 7. Workflow

- **Daily dev**  
  - Edit on host (GUI apps integrate with portals/keyring).  
  - Build/test inside toolbox (`toolbox enter dev-f42`).  
  - Toolchains from Homebrew are visible everywhere.  

- **Running builds**  
  ```bash
  toolbox run --container dev-f42 cargo test
  toolbox run --container dev-f42 rake spec
  toolbox run --container dev-f42 go build ./...
  ```

- **Steam & gaming**  
  - Install Steam Flatpak.  
  - Keep library on external/secondary drive.  
  - Proton GE handled through Steam.  

---

## 8. When to use Host vs Toolbox

- **Host (rpm-ostree/Flatpak)**  
  - Services: Tailscale, Proton VPN.  
  - Desktop apps: Signal, Spotify, browsers, etc.  
  - Editors: Zed/Helix/VS Code (host GUI).  

- **Toolbox**  
  - System headers and build deps.  
  - Compilation of Ruby, Rust crates with native deps, Go+cgo.  
  - Running test suites.  

---

## 9. Advantages of this model

- One shared **Homebrew tree** at `/home/linuxbrew/.linuxbrew`.  
- Immutable host remains clean.  
- Toolboxes provide reproducible build environments.  
- GUI apps integrate smoothly with host.  
- Minimal duplication: one copy of each language/toolchain, shared across host and toolboxes.  
