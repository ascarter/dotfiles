# Shell completions for docker
if command -v docker > /dev/null 2>&1 ; then
	if [ -n "$BASH_VERSION" ]; then
	  source <(docker completion bash)
	elif [ -n "$ZSH_VERSION" ]; then
	  source <(docker completion zsh)
	fi
fi
