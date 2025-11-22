# =====================================
# Key bindings (Emacs mode with Vim-inspired enhancements)
# =====================================

# Enable Emacs editing mode
bindkey -e

# Edit command line in $EDITOR (Helix/Zed)
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line        # Ctrl-X Ctrl-E to open current line in $EDITOR

# Vim-like movement on Meta-h/j/k/l (useful on HHKB without arrows)
bindkey '^[h' backward-char
bindkey '^[l' forward-char
bindkey '^[j' down-line-or-history
bindkey '^[k' up-line-or-history

# Explicit standard movements/history (some already default)
bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line

# Word motions (Meta-b/f are default; declare for clarity)
bindkey '^[b' backward-word
bindkey '^[f' forward-word

# Deletions / kills
bindkey '^W' backward-kill-word         # kill previous word
bindkey '^[d' kill-word                 # Meta-d kill next word
bindkey '^K' kill-line                  # kill to end of line
bindkey '^U' backward-kill-line         # kill to start of line
bindkey '^[t' transpose-words           # swap adjacent words

# Backspace variations
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
