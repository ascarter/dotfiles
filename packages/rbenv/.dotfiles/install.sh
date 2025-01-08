install() {
  # local git_url="https://github.com/rbenv/rbenv.git"
  # local rbenv_dir="${1}/.rbenv"

  # if [ -d "${rbenv_dir}" ]; then
  #   git -C ${rbenv_dir} pull
  # else
  #   # Clone rbenv
  #   git clone $git_url ${rbenv_dir}
  # fi

  curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash

  #eval "$(${rbenv_dir}/bin/rbenv init - zsh)"
  rbenv --version
}

install ${TARGET}
