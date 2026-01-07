mod line;
mod tab;

use std::collections::BTreeMap;

use crate::line::tab_line;
use crate::tab::tab_style;
use zellij_tile::prelude::*;

const GHOST_ICON: &str = "󰊠";

#[derive(Debug, Default)]
pub struct LinePart {
    part: String,
    len: usize,
}

#[derive(Default)]
struct State {
    tabs: Vec<TabInfo>,
    active_tab_idx: usize,
    mode_info: ModeInfo,
    tab_line: Vec<LinePart>,
    panes: PaneManifest,
}

register_plugin!(State);

impl ZellijPlugin for State {
    fn load(&mut self, _configuration: BTreeMap<String, String>) {
        set_selectable(false);
        request_permission(&[PermissionType::ReadApplicationState]);
        subscribe(&[
            EventType::TabUpdate,
            EventType::PaneUpdate,
            EventType::ModeUpdate,
        ]);
    }

    fn update(&mut self, event: Event) -> bool {
        let mut should_render = false;
        match event {
            Event::ModeUpdate(mode_info) => {
                if self.mode_info != mode_info {
                    should_render = true;
                }
                self.mode_info = mode_info;
            },
            Event::TabUpdate(tabs) => {
                let active_tab_idx = tabs.iter().position(|t| t.active).unwrap_or(0);
                if self.active_tab_idx != active_tab_idx || self.tabs != tabs {
                    should_render = true;
                }
                self.active_tab_idx = active_tab_idx;
                self.tabs = tabs;
            },
            Event::PaneUpdate(panes) => {
                if self.panes != panes {
                    should_render = true;
                }
                self.panes = panes;
            },
            _ => {},
        }
        should_render
    }

    fn render(&mut self, _rows: usize, cols: usize) {
        if self.tabs.is_empty() {
            return;
        }

        let mut all_tabs: Vec<LinePart> = vec![];
        let mut is_alternate_tab = false;

        for t in &self.tabs {
            let index = t.position + 1;
            let _ = &self.panes;
            let label = format!("{} {}", index, GHOST_ICON);
            let tab = tab_style(
                label,
                t,
                is_alternate_tab,
                self.mode_info.style.colors,
            );
            is_alternate_tab = !is_alternate_tab;
            all_tabs.push(tab);
        }

        let background = self.mode_info.style.colors.text_unselected.background;

        self.tab_line = tab_line(
            all_tabs,
            self.active_tab_idx,
            cols.saturating_sub(1),
            self.mode_info.style.colors,
        );

        let output = self
            .tab_line
            .iter()
            .fold(String::new(), |output, part| output + &part.part);

        match background {
            PaletteColor::Rgb((r, g, b)) => {
                print!("{}\u{1b}[48;2;{};{};{}m\u{1b}[0K", output, r, g, b);
            },
            PaletteColor::EightBit(color) => {
                print!("{}\u{1b}[48;5;{}m\u{1b}[0K", output, color);
            },
        }
    }
}
