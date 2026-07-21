local wezterm = require 'wezterm'
local act = wezterm.action

local config = wezterm.config_builder()
config:set_strict_mode(true)

local config_home = os.getenv 'XDG_CONFIG_HOME'
if not config_home or #config_home == 0 then
  config_home = wezterm.home_dir .. '/.config'
end
local installed_config_dir = config_home .. '/wezterm'

-- Load bundled/user-installed fonts directly. This also works when macOS
-- CoreText hasn't registered a newly copied font yet.
config.font_dirs = {
  wezterm.home_dir .. '/Library/Fonts',
}

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
        fg_color = palette.wine,
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

-- Keep the base opaque so macOS Spaces/fullscreen never fall through to a
-- black compositor backdrop. The layers below provide the glass treatment.
config.window_background_opacity = 1.0
config.macos_window_background_blur = 32
config.background = {
  {
    -- A stable crimson wash keeps the theme warm in both windowed and
    -- fullscreen modes, independently of whatever is behind the window.
    source = { Color = palette.wine },
    width = '100%',
    height = '100%',
    opacity = 0.10,
  },
  {
    source = {
      File = installed_config_dir .. '/assets/crt-overlay.png',
    },
    attachment = 'Fixed',
    repeat_x = 'NoRepeat',
    repeat_y = 'NoRepeat',
    width = '100%',
    height = '100%',
    -- Preserve the scanlines and bloom without letting the black vignette
    -- crush the fullscreen background.
    opacity = 0.42,
  },
}

config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE|MACOS_FORCE_ENABLE_SHADOW'
config.integrated_title_button_style = 'MacOsNative'
config.integrated_title_button_alignment = 'Left'
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
local max_tab_width = 32
local macos_title_button_cells = 9
config.tab_max_width = max_tab_width

local left_cap = ''
local right_cap = ''

local function tab_title(tab)
  if tab.tab_title and #tab.tab_title > 0 then
    return tab.tab_title
  end
  return tab.active_pane.title
end

wezterm.on('format-tab-title', function(tab, tabs, panes, cfg, hover, max_width)
  local foreground = palette.wine
  local intensity = 'Normal'
  if tab.is_active then
    foreground = palette.wine
    intensity = 'Bold'
  elseif hover then
    foreground = palette.pink
  end

  local is_first = tab.tab_index == 0
  local is_last = tab.tab_index == #tabs - 1
  local edge_width = (is_first and 1 or 0) + (is_last and 1 or 0)
  local prefix = tostring(tab.tab_index + 1) .. '  '
  local title = wezterm.truncate_right(
    tab_title(tab),
    math.max(1, max_width - wezterm.column_width(prefix) - edge_width - 2)
  )

  local elements = {}
  if is_first then
    table.insert(elements, { Background = { Color = palette.strip } })
    table.insert(elements, { Foreground = { Color = palette.background } })
    table.insert(elements, { Text = left_cap })
  end

  table.insert(elements, { Background = { Color = palette.background } })
  table.insert(elements, { Foreground = { Color = foreground } })
  table.insert(elements, { Attribute = { Intensity = intensity } })
  table.insert(elements, { Text = ' ' .. prefix .. title .. ' ' })

  if is_last then
    table.insert(elements, { Background = { Color = palette.strip } })
    table.insert(elements, { Foreground = { Color = palette.background } })
    table.insert(elements, { Text = right_cap })
  end
  table.insert(elements, 'ResetAttributes')

  return elements
end)

local function mux_tab_title(tab)
  local title = tab:get_title()
  if title and #title > 0 then
    return title
  end
  return tab:active_pane():get_title()
end

-- WezTerm has no tab_bar_align option, so reserve the exact number of cells
-- needed to center the complete capsule, like Kitty's `tab_bar_align center`.
wezterm.on('update-status', function(window, pane)
  local mux_window = window:mux_window()
  local tabs = mux_window:tabs()
  local active_tab = mux_window:active_tab()
  if not active_tab or #tabs == 0 then
    window:set_left_status ''
    return
  end

  local capsule_width = 0
  for index, tab in ipairs(tabs) do
    local edge_width = (index == 1 and 1 or 0) + (index == #tabs and 1 or 0)
    local label = tostring(index) .. '  ' .. mux_tab_title(tab)
    local natural_width = wezterm.column_width(label) + edge_width + 2
    capsule_width = capsule_width + math.min(max_tab_width, natural_width)
  end

  local tab_size = active_tab:get_size()
  local window_size = window:get_dimensions()
  local cell_width = tab_size.pixel_width / tab_size.cols
  local tab_bar_columns = math.floor(window_size.pixel_width / cell_width)
  local left_padding = math.max(
    0,
    math.floor((tab_bar_columns - capsule_width) / 2) - macos_title_button_cells
  )
  window:set_left_status(wezterm.format {
    { Background = { Color = palette.strip } },
    { Text = string.rep(' ', left_padding) },
  })
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
