#!/usr/bin/env bash
set -euo pipefail

extension_id="blur-my-shell@aunetx"
extension_dir="${XDG_DATA_HOME:-$HOME/.local/share}/gnome-shell/extensions/${extension_id}"
schema_dir="${extension_dir}/schemas"
schema="org.gnome.shell.extensions.blur-my-shell.applications"

if [[ ! -d "$schema_dir" ]]; then
  printf 'Blur My Shell is not installed at %s\n' "$extension_dir" >&2
  printf 'Install the GNOME extension, then run this script again.\n' >&2
  exit 1
fi

gnome-extensions enable "$extension_id"
gsettings --schemadir "$schema_dir" set "$schema" blur true
gsettings --schemadir "$schema_dir" set "$schema" enable-all false
gsettings --schemadir "$schema_dir" set "$schema" whitelist "['kitty']"
gsettings --schemadir "$schema_dir" set "$schema" sigma 32
gsettings --schemadir "$schema_dir" set "$schema" brightness 1.0
gsettings --schemadir "$schema_dir" set "$schema" opacity 235
gsettings --schemadir "$schema_dir" set "$schema" dynamic-opacity false

printf 'Blur My Shell is configured for Kitty (blur 32, opacity 0.92).\n'
