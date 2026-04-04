export RUSTUP_HOME="${XDG_DATA_HOME}"/rustup
export CARGO_HOME="${XDG_DATA_HOME}"/cargo

if [[ -d ${CARGO_HOME}/bin ]]; then
  path=(${CARGO_HOME}/bin $path)
fi
