use unicode_width::UnicodeWidthStr;
use zellij_tile::prelude::*;
use zellij_tile_utils::style;

use crate::LinePart;

const APPLE_ICON: &str = "";

fn get_current_len(parts: &[LinePart]) -> usize {
    parts.iter().map(|p| p.len).sum()
}

fn prefix_part(palette: Styling) -> LinePart {
    let text = format!(" {} ", APPLE_ICON);
    let text_len = text.width();
    let text_color = palette.text_unselected.base;
    let bg_color = palette.text_unselected.background;
    let styled_text = style!(text_color, bg_color).bold().paint(text);
    LinePart {
        part: styled_text.to_string(),
        len: text_len,
    }
}

fn left_more_message(count: usize, palette: Styling) -> LinePart {
    if count == 0 {
        return LinePart::default();
    }
    let more_text = if count < 10000 {
        format!(" <+{} ", count)
    } else {
        " <+many ".to_string()
    };
    let text_len = more_text.width();
    let text_color = palette.text_unselected.base;
    let bg_color = palette.text_unselected.background;
    let styled_text = style!(text_color, bg_color).bold().paint(more_text);
    LinePart {
        part: styled_text.to_string(),
        len: text_len,
    }
}

fn right_more_message(count: usize, palette: Styling) -> LinePart {
    if count == 0 {
        return LinePart::default();
    }
    let more_text = if count < 10000 {
        format!(" +{}> ", count)
    } else {
        " +many> ".to_string()
    };
    let text_len = more_text.width();
    let text_color = palette.text_unselected.base;
    let bg_color = palette.text_unselected.background;
    let styled_text = style!(text_color, bg_color).bold().paint(more_text);
    LinePart {
        part: styled_text.to_string(),
        len: text_len,
    }
}

fn populate_tabs_in_tab_line(
    tabs_before_active: &mut Vec<LinePart>,
    tabs_after_active: &mut Vec<LinePart>,
    tabs_to_render: &mut Vec<LinePart>,
    cols: usize,
    palette: Styling,
) {
    let mut middle_size = get_current_len(tabs_to_render);

    let mut total_left = 0;
    let mut total_right = 0;
    loop {
        let left_count = tabs_before_active.len();
        let right_count = tabs_after_active.len();

        let collapsed_left = left_more_message(left_count, palette);
        let collapsed_right = right_more_message(right_count, palette);

        let total_size = collapsed_left.len + middle_size + collapsed_right.len;

        if total_size > cols {
            break;
        }

        let left = if let Some(tab) = tabs_before_active.last() {
            tab.len
        } else {
            usize::MAX
        };

        let right = if let Some(tab) = tabs_after_active.first() {
            tab.len
        } else {
            usize::MAX
        };

        let size_by_adding_left = left
            .saturating_add(total_size)
            .saturating_sub(if left_count == 1 { collapsed_left.len } else { 0 });
        let size_by_adding_right = right
            .saturating_add(total_size)
            .saturating_sub(if right_count == 1 { collapsed_right.len } else { 0 });

        let left_fits = size_by_adding_left <= cols;
        let right_fits = size_by_adding_right <= cols;

        if (total_left <= total_right || !right_fits) && left_fits {
            let tab = tabs_before_active.pop().unwrap();
            middle_size += tab.len;
            total_left += tab.len;
            tabs_to_render.insert(0, tab);
        } else if right_fits {
            let tab = tabs_after_active.remove(0);
            middle_size += tab.len;
            total_right += tab.len;
            tabs_to_render.push(tab);
        } else {
            tabs_to_render.insert(0, collapsed_left);
            tabs_to_render.push(collapsed_right);
            break;
        }
    }
}

pub fn tab_line(
    mut all_tabs: Vec<LinePart>,
    active_tab_index: usize,
    cols: usize,
    palette: Styling,
) -> Vec<LinePart> {
    let mut tabs_after_active = all_tabs.split_off(active_tab_index);
    let mut tabs_before_active = all_tabs;
    let active_tab = if !tabs_after_active.is_empty() {
        tabs_after_active.remove(0)
    } else {
        tabs_before_active.pop().unwrap()
    };

    let mut prefix = vec![prefix_part(palette)];
    let non_tab_len = get_current_len(&prefix);

    if non_tab_len + active_tab.len > cols {
        return prefix;
    }

    let mut tabs_to_render = vec![active_tab];
    populate_tabs_in_tab_line(
        &mut tabs_before_active,
        &mut tabs_after_active,
        &mut tabs_to_render,
        cols.saturating_sub(non_tab_len),
        palette,
    );
    prefix.append(&mut tabs_to_render);
    prefix
}
