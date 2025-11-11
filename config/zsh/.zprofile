# Configure readline
# export INPUTRC="${XDG_CONFIG_HOME}/readline/inputrc"

# =====================================
# Load profile modules
# =====================================

for profile in "${ZDOTDIR}"/profile.d/*.zsh(.N); do
  source "$profile"
done
unset profile
