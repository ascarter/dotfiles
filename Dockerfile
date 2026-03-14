FROM fedora:latest

RUN dnf install -y \
  bash \
  git \
  vim \
  wget \
  curl \
  procps-ng \
  sudo \
  shadow-utils \
  zsh \
  && dnf clean all

# Create a user (name: dev, uid/gid: 1000)
RUN groupadd -g 1000 dev && \
  useradd -u 1000 -g 1000 -m -s /bin/bash dev

RUN echo "dev ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/dev && \
  chmod 0440 /etc/sudoers.d/dev

RUN mkdir -p /home/dev/.local/share/dotfiles && \
  chown -R dev:dev /home/dev/.local

USER dev
WORKDIR /home/dev
