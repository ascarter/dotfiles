bindkey -e

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

bindkey '^[h' backward-char
bindkey '^[j' down-line-or-history
bindkey '^[k' up-line-or-history
bindkey '^[l' forward-char

bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line

bindkey '^[b' backward-word
bindkey '^[f' forward-word

bindkey '^W' backward-kill-word
bindkey '^[d' kill-word
bindkey '^K' kill-line
bindkey '^U' backward-kill-line
bindkey '^[t' transpose-words

bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char

