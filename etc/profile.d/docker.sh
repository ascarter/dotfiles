# Shell completions for docker
if [ -n "$BASH_VERSION" ]; then
  source <(docker completion bash)
elif [ -n "$ZSH_VERSION" ]; then
  source <(docker completion zsh)
fi
