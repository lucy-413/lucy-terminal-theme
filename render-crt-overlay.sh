#!/usr/bin/env bash
set -euo pipefail

reference_width=3440
reference_height=1440
resolution="${1:-${reference_width}x${reference_height}}"

if [[ ! "$resolution" =~ ^([0-9]+)x([0-9]+)$ ]]; then
  printf 'Usage: %s [WIDTHxHEIGHT]\n' "$0" >&2
  exit 1
fi

width="${BASH_REMATCH[1]}"
height="${BASH_REMATCH[2]}"
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source_svg="${project_dir}/kitty/assets/crt-overlay.svg"
output_png="${project_dir}/kitty/assets/crt-overlay.png"
wezterm_output_png="${project_dir}/wezterm/assets/crt-overlay.png"

if ! command -v rsvg-convert >/dev/null 2>&1; then
  printf 'rsvg-convert is required to render the CRT overlay.\n' >&2
  exit 1
fi

scaled() {
  awk -v value="$1" -v target="$height" -v reference="$reference_height" \
    'BEGIN { printf "%d", (value * target / reference) + 0.5 }'
}

at_least() {
  if (( $2 < $1 )); then printf '%d' "$1"; else printf '%d' "$2"; fi
}

scan_pitch="$(at_least 3 "$(scaled 6)")"
scan_black="$(at_least 1 "$(scaled 2)")"
scan_pink="$(at_least 1 "$(scaled 1)")"
corner_rx="$(scaled 156)"
corner_ry="$(scaled 118)"
corner_blur="$(at_least 1 "$(scaled 14)")"
bleed=$((4 * corner_blur))
bleed_pos=$((-bleed))
bleed_width=$((width + 2 * bleed))
bleed_height=$((height + 2 * bleed))

temporary_svg="$(mktemp "${TMPDIR:-/tmp}/lucy-crt-overlay.XXXXXX")"
trap 'rm -f -- "$temporary_svg"' EXIT

sed \
  -e "s/@W@/${width}/g" \
  -e "s/@H@/${height}/g" \
  -e "s/@SCAN_PITCH@/${scan_pitch}/g" \
  -e "s/@SCAN_BLACK@/${scan_black}/g" \
  -e "s/@SCAN_PINK@/${scan_pink}/g" \
  -e "s/@CORNER_RX@/${corner_rx}/g" \
  -e "s/@CORNER_RY@/${corner_ry}/g" \
  -e "s/@CORNER_BLUR@/${corner_blur}/g" \
  -e "s/@BLEED_POS@/${bleed_pos}/g" \
  -e "s/@BLEED_W@/${bleed_width}/g" \
  -e "s/@BLEED_H@/${bleed_height}/g" \
  "$source_svg" > "$temporary_svg"

if grep -Eq '@[A-Z_]+' "$temporary_svg"; then
  printf 'The rendered SVG still contains unresolved template tokens.\n' >&2
  exit 1
fi

rsvg-convert -w "$width" -h "$height" -o "$output_png" "$temporary_svg"
mkdir -p "$(dirname "$wezterm_output_png")"
install -m 0644 "$output_png" "$wezterm_output_png"
printf 'Rendered the Kitty and WezTerm PNG assets from the LucyGRUB CRT SVG.\n'
