#!/bin/sh

CONFIG_FILE=${XDG_CONFIG_HOME:=$HOME/.config}/alacritty/alacritty.toml

# Use package manager to install alacritty
case "${ID}" in
"macos")  brew_install alacritty  ;;
"fedora") dnf_install alacritty ;;
"ubuntu") apt_install alacritty ;;
esac

# Generate configuration
if [[ -f ${CONFIG_FILE} ]] && [ $FORCE -eq 0 ]; then
    echo "==> Configuration file already exists at ${CONFIG_FILE}"
else
    # Write configuration file to ~/.config/alacritty/alacritty.toml
    mkdir -p $(dirname ${CONFIG_FILE})
    render_template ${DOTFILES_LIB}/alacritty/alacritty.template.toml ${CONFIG_FILE} \
        "DOTFILES_LIB=${DOTFILES_LIB}"     \
        "DOTFILES_THEME=${DOTFILES_THEME}" \
        "DOTFILES_FONT=${DOTFILES_FONT}"   \
        "DOTFILES_FONT_SIZE=${DOTFILES_FONT_SIZE}"

#     cat <<EOF > ${CONFIG_FILE}
# import = [
#   "${DOTFILES_LIB}/alacritty/alacritty.toml",
#   "${DOTFILES_LIB}/alacritty/themes/${DOTFILES_THEME}.toml"
# ]
# EOF
  echo "Configuration file created at ${CONFIG_FILE}"
fi
