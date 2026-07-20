#!/usr/bin/env bash
set -euo pipefail

replace_zshrc=false

usage() {
  cat <<'EOF'
Usage: ./install-macos.sh [--replace-zshrc]

Installs the Lucy WezTerm configuration and Powerlevel10k preset.
An existing ~/.zshrc is preserved unless --replace-zshrc is supplied.
EOF
}

for argument in "$@"; do
  case "$argument" in
    --replace-zshrc)
      replace_zshrc=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n\n' "$argument" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'This installer is for macOS. Use ./install.sh for the Kitty/Linux version.\n' >&2
  exit 1
fi

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
wezterm_source="$project_dir/wezterm"
wezterm_target="${XDG_CONFIG_HOME:-$HOME/.config}/wezterm"
p10k_source="$project_dir/zsh/.p10k.zsh"
zshrc_source="$project_dir/zsh/.zshrc.macos"
p10k_target="$HOME/.p10k.zsh"
zshrc_target="$HOME/.zshrc"
timestamp="$(date +%Y%m%d-%H%M%S)"

backup_file() {
  local target="$1"
  if [[ -e "$target" || -L "$target" ]]; then
    cp -p "$target" "${target}.bak.${timestamp}"
    printf 'Backed up %s\n' "$target"
  fi
}

mkdir -p "$wezterm_target/assets"

backup_file "$wezterm_target/wezterm.lua"
install -m 0644 "$wezterm_source/wezterm.lua" "$wezterm_target/wezterm.lua"

backup_file "$wezterm_target/assets/crt-overlay.png"
install -m 0644 "$wezterm_source/assets/crt-overlay.png" "$wezterm_target/assets/crt-overlay.png"

backup_file "$p10k_target"
install -m 0644 "$p10k_source" "$p10k_target"

if [[ ! -e "$zshrc_target" ]]; then
  install -m 0644 "$zshrc_source" "$zshrc_target"
  printf 'Installed %s\n' "$zshrc_target"
elif [[ "$replace_zshrc" == true ]]; then
  backup_file "$zshrc_target"
  install -m 0644 "$zshrc_source" "$zshrc_target"
  printf 'Replaced %s (the previous file was backed up).\n' "$zshrc_target"
else
  printf 'Preserved existing %s\n' "$zshrc_target"
  printf 'Merge zsh/.zshrc.macos manually, or rerun with --replace-zshrc.\n'
fi

wezterm_bin=""
if command -v wezterm >/dev/null 2>&1; then
  wezterm_bin="$(command -v wezterm)"
elif [[ -x /Applications/WezTerm.app/Contents/MacOS/wezterm ]]; then
  wezterm_bin="/Applications/WezTerm.app/Contents/MacOS/wezterm"
fi

if [[ -n "$wezterm_bin" ]]; then
  "$wezterm_bin" --config-file "$wezterm_target/wezterm.lua" show-keys >/dev/null
  printf 'Validated the installed WezTerm configuration.\n'
else
  printf 'Warning: WezTerm is not installed; config validation was skipped.\n' >&2
fi

if [[ ! -r "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
  printf 'Warning: install Oh My Zsh at ~/.oh-my-zsh before starting the themed shell.\n' >&2
fi

p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [[ ! -r "$p10k_dir/powerlevel10k.zsh-theme" ]]; then
  printf 'Warning: install Powerlevel10k at %s before starting the themed shell.\n' "$p10k_dir" >&2
fi

printf '\nLucy Terminal Theme for macOS is installed.\n'
printf 'WezTerm config: %s\n' "$wezterm_target/wezterm.lua"
printf 'Install MesloLGS NF, then restart the shell with: exec zsh\n'
printf 'WezTerm reloads the configuration automatically.\n'
