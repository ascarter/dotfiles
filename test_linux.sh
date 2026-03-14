#!/bin/sh

image="fedora-dotfiles"
volumes="-v $PWD/.:/home/dev/.local/share/dotfiles"
docker build -t ${image} .
docker run -it --rm ${volumes} --name fedora-dotfiles ${image}:latest bash
