# Font System Reference

The font system manages desktop font installation from GitHub releases.
Fonts are defined as declarative recipes in `fonts/` and installed via
`dotfiles font install`.

## Commands

```sh
dotfiles font install           # Install all fonts defined in fonts/
dotfiles font install <name>    # Install a single font by recipe name
dotfiles font list              # Show installed fonts with versions
```

`install` always resolves the latest release, downloads if needed, and copies
TTF files flat into the OS font directory. It is idempotent — running it again
skips fonts already at the latest tag.

## Storage Layout

Fonts reuse the opt-space storage infrastructure from `lib/opt.sh`:

```
~/.local/opt/cellar/<name>/<tag>/   Extracted archive (TOOLS_CELLAR)
~/.cache/tools/<name>/              Downloaded archives (TOOLS_CACHE)
~/.local/state/tools/<name>         Installed tag receipt (TOOLS_STATE)
```

Font files are **copied** (not symlinked) flat into the OS font directory:

| Platform | Font directory |
|----------|---------------|
| macOS    | `~/Library/Fonts/` |
| Linux    | `~/.local/share/fonts/` |

On Linux, `fc-cache -f` is run automatically after installing fonts.

## Writing a Font Recipe

Recipes are declarative config files in `fonts/` (no shebang, no boilerplate).
The driver (`lib/font.sh`) sources the recipe to load variables and optional
hooks, then executes the install flow.

### Config Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `FONT_REPO` | yes* | GitHub `owner/repo` for releases |
| `FONT_ASSET` | yes* | Release asset glob pattern |
| `FONT_GLOB` | no | Glob to find TTF files in extracted archive (default: `*.ttf`) |
| `FONT_STRIP_COMPONENTS` | no | Strip leading directory from zip/tar (like tar --strip-components) |

*Required unless a `font_download` hook is defined.

### Hook Functions

| Hook | Default | Override when |
|------|---------|---------------|
| `font_latest_tag` | `tool_latest_tag "$FONT_REPO"` | Non-standard tag format (e.g. IBM Plex NPM-style) |
| `font_download` | `font_gh_install` with FONT_REPO + FONT_ASSET | Non-GitHub source or custom download logic |
| `font_post_install` | Copy TTFs matching FONT_GLOB to OS font dir | Custom file filtering or layout |

### Driver Flow

1. **Reset state** — clear `FONT_*` variables and hook functions
2. **Source recipe** — loads variables and optional hooks
3. **Download** — call `font_download` hook (default: `font_gh_install`)
   - Resolve tag via `font_latest_tag` hook or `tool_latest_tag`
   - Skip if already installed at this tag
   - Download archive to `TOOLS_CACHE/<name>/`
   - Extract to `TOOLS_CELLAR/<name>/<tag>/`
   - Record tag to `TOOLS_STATE/<name>`
4. **Post-install** — call `font_post_install` hook (default: copy TTFs)
5. **Refresh cache** — `fc-cache -f` on Linux

## Recipe Examples

### Minimal (GitHub release with flat TTFs)

```bash
# fonts/juliamono.sh
FONT_REPO=cormullion/juliamono
FONT_ASSET="JuliaMono-ttf.tar.gz"
```

### Nested archive with glob

```bash
# fonts/firacode.sh
FONT_REPO=tonsky/FiraCode
FONT_ASSET="Fira_Code_v*.zip"
FONT_GLOB="ttf/*.ttf"
```

### Custom tag resolution (multi-family repo)

IBM Plex publishes separate releases per font family with NPM-style tags.
A `font_latest_tag` hook filters to the correct family:

```bash
# fonts/ibm-plex-mono.sh
FONT_REPO=IBM/plex
FONT_ASSET="ibm-plex-mono.zip"
FONT_GLOB="fonts/complete/ttf/*.ttf"
FONT_STRIP_COMPONENTS=1

font_latest_tag() {
  gh release list --repo IBM/plex --limit 100 \
    --json tagName,isDraft,isPrerelease \
    --jq 'map(select((.isDraft | not) and (.isPrerelease | not) and (.tagName | startswith("@ibm/plex-mono@"))))[0].tagName'
}
```

### Deeply nested archive

```bash
# fonts/firacode.sh
FONT_REPO=tonsky/FiraCode
FONT_ASSET="Fira_Code_v*.zip"
FONT_GLOB="ttf/*.ttf"
```

## Available Fonts

| Recipe | Font | Repo |
|--------|------|------|
| `juliamono` | JuliaMono | cormullion/juliamono |
| `firacode` | Fira Code | tonsky/FiraCode |
| `ibm-plex-mono` | IBM Plex Mono | IBM/plex |
| `ibm-plex-sans` | IBM Plex Sans | IBM/plex |
| `ibm-plex-serif` | IBM Plex Serif | IBM/plex |
| `monaspace` | Monaspace | githubnext/monaspace |
