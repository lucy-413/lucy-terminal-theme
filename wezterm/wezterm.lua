local wezterm = require 'wezterm'
local act = wezterm.action

local config = wezterm.config_builder()
config:set_strict_mode(true)

local palette = {
  background = '#1A1A1A',
  strip = '#101010',
  wine = '#A4133C',
  pink = '#FB6F92',
  foreground = '#E6D1D7',
  muted = '#76515A',
}

config.default_prog = { '/bin/zsh', '-l' }
config.font = wezterm.font_with_fallback {
  'MesloLGS NF',
  'Menlo',
  'Apple Color Emoji',
}
config.font_size = 13.5
config.line_height = 1.05

-- Avoid the native IME candidate popup and highlighted preedit text.
-- Shell-rendered inline suggestions are unaffected.
config.use_ime = false

config.color_schemes = {
  ['LucyGRUB Crimson'] = {
    foreground = palette.foreground,
    background = palette.background,
    cursor_bg = palette.pink,
    cursor_fg = palette.background,
    cursor_border = palette.pink,
    selection_fg = '#FFF4F7',
    selection_bg = palette.wine,
    scrollbar_thumb = '#4D2731',
    split = palette.wine,
    ansi = {
      '#1A1A1A',
      '#A4133C',
      '#8E9C72',
      '#C28F5C',
      '#6F829E',
      '#A94E6A',
      '#658F8C',
      '#C9B6BB',
    },
    brights = {
      '#594047',
      '#FB6F92',
      '#B3C58D',
      '#E5B477',
      '#91A9CB',
      '#E37899',
      '#8ABBB6',
      '#FFF4F7',
    },
    tab_bar = {
      background = palette.strip,
      active_tab = {
        bg_color = palette.background,
        fg_color = palette.wine,
        intensity = 'Bold',
      },
      inactive_tab = {
        bg_color = palette.background,
        fg_color = palette.muted,
      },
      inactive_tab_hover = {
        bg_color = palette.background,
        fg_color = palette.pink,
      },
      new_tab = {
        bg_color = palette.strip,
        fg_color = palette.wine,
      },
      new_tab_hover = {
        bg_color = palette.strip,
        fg_color = palette.pink,
      },
    },
  },
}
config.color_scheme = 'LucyGRUB Crimson'

-- Keep the image layer transparent: an opaque layer would hide the macOS blur.
config.window_background_opacity = 0.92
config.macos_window_background_blur = 32
config.background = {
  {
    source = {
      File = wezterm.config_dir .. '/assets/crt-overlay.png',
    },
    attachment = 'Fixed',
    repeat_x = 'NoRepeat',
    repeat_y = 'NoRepeat',
    width = '100%',
    height = '100%',
    opacity = 0.22,
  },
}

config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE|MACOS_FORCE_ENABLE_SHADOW'
config.integrated_title_button_style = 'MacOsNative'
config.window_padding = {
  left = 12,
  right = 12,
  top = 8,
  bottom = 12,
}

config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = false
config.show_new_tab_button_in_tab_bar = false
config.show_tab_index_in_tab_bar = false
config.tab_max_width = 32

local left_cap = ''
local right_cap = ''

local function tab_title(tab)
  if tab.tab_title and #tab.tab_title > 0 then
    return tab.tab_title
  end
  return tab.active_pane.title
end

wezterm.on('format-tab-title', function(tab, tabs, panes, cfg, hover, max_width)
  local foreground = palette.muted
  local intensity = 'Normal'
  if tab.is_active then
    foreground = palette.wine
    intensity = 'Bold'
  elseif hover then
    foreground = palette.pink
  end

  local prefix = tostring(tab.tab_index + 1) .. '  '
  local title = wezterm.truncate_right(
    tab_title(tab),
    math.max(1, max_width - #prefix - 5)
  )

  return {
    { Background = { Color = palette.strip } },
    { Foreground = { Color = palette.background } },
    { Text = left_cap },
    { Background = { Color = palette.background } },
    { Foreground = { Color = foreground } },
    { Attribute = { Intensity = intensity } },
    { Text = ' ' .. prefix .. title .. ' ' },
    { Background = { Color = palette.strip } },
    { Foreground = { Color = palette.background } },
    { Text = right_cap .. ' ' },
    'ResetAttributes',
  }
end)

config.keys = {
  { key = 't', mods = 'CMD', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CMD', action = act.CloseCurrentTab { confirm = true } },
  { key = '[', mods = 'CMD|SHIFT', action = act.ActivateTabRelative(-1) },
  { key = ']', mods = 'CMD|SHIFT', action = act.ActivateTabRelative(1) },
  { key = 'Tab', mods = 'CTRL', action = act.ActivateTabRelative(1) },
  { key = 'Tab', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(-1) },
  { key = 'LeftArrow', mods = 'CMD|SHIFT', action = act.MoveTabRelative(-1) },
  { key = 'RightArrow', mods = 'CMD|SHIFT', action = act.MoveTabRelative(1) },
}

config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 600
config.hide_mouse_cursor_when_typing = true
config.audible_bell = 'Disabled'
config.scrollback_lines = 10000
config.enable_scroll_bar = false

return config
