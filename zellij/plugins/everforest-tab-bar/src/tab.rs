use unicode_width::UnicodeWidthStr;
use zellij_tile::prelude::*;
use zellij_tile_utils::style;

use crate::LinePart;

const HALF_ROUND_OPEN: &str = "\u{e0b6}";
const HALF_ROUND_CLOSE: &str = "\u{e0b4}";

pub fn tab_style(
    text: String,
    tab: &TabInfo,
    is_alternate_tab: bool,
    palette: Styling,
) -> LinePart {
    let alternate_tab_color = if is_alternate_tab {
        palette.ribbon_unselected.emphasis_1
    } else {
        palette.ribbon_unselected.background
    };

    let background_color = if tab.active {
        palette.ribbon_selected.background
    } else if is_alternate_tab {
        alternate_tab_color
    } else {
        palette.ribbon_unselected.background
    };

    let foreground_color = if tab.active {
        palette.ribbon_selected.base
    } else {
        palette.ribbon_unselected.base
    };

    let bar_bg = palette.text_unselected.background;

    let left = style!(background_color, bar_bg).paint(HALF_ROUND_OPEN);
    let right = style!(background_color, bar_bg).paint(HALF_ROUND_CLOSE);

    let mut tab_text_style = style!(foreground_color, background_color);
    if tab.active {
        tab_text_style = tab_text_style.bold();
    }

    let tab_text = tab_text_style.paint(format!(" {} ", text));
    let tab_text_len = text.width() + 2 + HALF_ROUND_OPEN.width() + HALF_ROUND_CLOSE.width();

    let mut part = String::new();
    part.push_str(&left.to_string());
    part.push_str(&tab_text.to_string());
    part.push_str(&right.to_string());

    LinePart {
        part,
        len: tab_text_len,
    }
}
