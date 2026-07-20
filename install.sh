#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
kitty_source="${project_dir}/kitty"
kitty_target="${XDG_CONFIG_HOME:-$HOME/.config}/kitty"
timestamp="$(date +%Y%m%d-%H%M%S)"

backup_file() {
  local target="$1"
  if [[ -e "$target" ]]; then
    cp -a -- "$target" "${target}.bak.${timestamp}"
    printf 'Backed up %s\n' "$target"
  fi
}

mkdir -p -- "${kitty_target}/assets"
for file in kitty.conf lucy-crimson.conf tab_bar.py; do
  backup_file "${kitty_target}/${file}"
  install -m 0644 -- "${kitty_source}/${file}" "${kitty_target}/${file}"
done
backup_file "${kitty_target}/assets/crt-overlay.png"
install -m 0644 -- "${kitty_source}/assets/crt-overlay.png" "${kitty_target}/assets/crt-overlay.png"

if [[ "${1:-}" != "--kitty-only" ]]; then
  backup_file "${HOME}/.p10k.zsh"
  install -m 0644 -- "${project_dir}/zsh/.p10k.zsh" "${HOME}/.p10k.zsh"
fi

printf '\nLucy Terminal Theme installed.\n'
printf 'Add the contents of zsh/zshrc.snippet to ~/.zshrc if Powerlevel10k is not already loaded.\n'
printf 'Restart Kitty to load the custom tab renderer and CRT overlay.\n'
