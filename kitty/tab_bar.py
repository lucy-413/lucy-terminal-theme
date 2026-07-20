"""Draw Kitty's complete tab bar as one rounded capsule."""

from kitty.fast_data_types import Screen
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb, draw_title


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_tab_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    capsule_bg = screen.cursor.bg
    tab_fg = screen.cursor.fg
    bar_bg = as_rgb(int(draw_data.default_bg))

    # Only the first tab draws the capsule's left outer edge.
    if index == 1:
        screen.cursor.bg = bar_bg
        screen.cursor.fg = capsule_bg
        screen.draw("")

    screen.cursor.bg = capsule_bg
    screen.cursor.fg = tab_fg
    screen.draw(" ")
    title_start = screen.cursor.x
    draw_title(draw_data, screen, tab, index, max(1, max_tab_length - 4))

    title_limit = max(title_start + 1, before + max_tab_length - 2)
    if screen.cursor.x > title_limit:
        screen.cursor.x = title_limit - 1
        screen.draw("…")
    screen.draw(" ")

    # Only the final tab draws the capsule's right outer edge.
    if is_last:
        screen.cursor.bg = bar_bg
        screen.cursor.fg = capsule_bg
        screen.draw("")
    return screen.cursor.x
