"""Textual TUI per herdr-git-tui spec."""

from __future__ import annotations

import contextlib
import os
import re
import webbrowser
from enum import Enum
from pathlib import Path
from typing import ClassVar

from rich.markdown import Markdown
from rich.markup import escape as rich_escape
from rich.text import Text
from rich.console import RenderableType

from textual import events, on, work
from textual.app import App, ComposeResult
from textual.theme import Theme
from textual.binding import Binding
from textual.containers import Container, Vertical, VerticalScroll
from textual.widgets import DataTable, Input, Static

from . import forge
from .repo import RepoContext, refresh_branch, require_cli, try_resolve_repo
from .terminal import hard_exit, restore_terminal

ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")


class Tab(str, Enum):
    MRS = "mrs"
    CI = "ci"
    ISSUES = "issues"

    def next(self) -> Tab:
        order = [Tab.MRS, Tab.CI, Tab.ISSUES]
        return order[(order.index(self) + 1) % len(order)]

    def prev(self) -> Tab:
        order = [Tab.MRS, Tab.CI, Tab.ISSUES]
        return order[(order.index(self) - 1) % len(order)]


class SearchInput(Input):
    def on_key(self, event: events.Key) -> None:
        if event.key == "tab":
            event.prevent_default()
            event.stop()
            self.app.action_focus_list()


NORD_BG = "#2E3440"

NORD_SOLID_THEME = Theme(
    name="nord-solid",
    primary="#88C0D0",
    secondary="#81A1C1",
    accent="#B48EAD",
    foreground="#D8DEE9",
    background=NORD_BG,
    surface=NORD_BG,
    panel="#434C5E",
    success="#A3BE8C",
    warning="#EBCB8B",
    error="#BF616A",
    variables={
        "block-cursor-background": "#88C0D0",
        "block-cursor-foreground": NORD_BG,
        "footer-key-foreground": "#88C0D0",
        "input-selection-background": "#81a1c1 35%",
    },
)

_SHARED_CSS = """
    .field-panel:focus-within {
        border: tall $accent;
    }
    #filter-panel {
        height: auto;
        margin-bottom: 1;
    }
    #filter {
        width: 100%;
        border: none;
        padding: 0;
        height: auto;
        min-height: 1;
    }
    #filter:focus {
        border: none;
    }
    #list-panel {
        height: 1fr;
        min-height: 5;
        padding: 0;
    }
    #list-panel:focus-within {
        border: tall $accent;
    }
    #table {
        height: 100%;
        width: 100%;
        padding: 0 1;
    }
    .dim { color: $text-muted; }
    DataTable {
        color: $foreground;
    }
    DataTable > .datatable--header {
        color: $accent;
    }
    #preview-overlay {
        layer: overlay;
        display: none;
        width: 100%;
        height: 100%;
    }
    #preview-overlay.open {
        display: block;
    }
    #preview-frame {
        width: 100%;
        height: 100%;
        border: solid $accent;
        padding: 1;
        color: $foreground;
    }
    #preview-hint {
        height: auto;
        color: $text-muted;
    }
    #preview-header {
        height: auto;
        padding-bottom: 1;
        border-bottom: solid $border;
    }
    #preview-body {
        height: 1fr;
    }
"""

_EMBEDDED_CSS = (
    """
    Screen {
        layout: vertical;
        background: transparent;
    }
    #top { height: auto; padding: 0 1; background: transparent; }
    #body {
        height: 1fr;
        margin: 0 1 1 1;
        background: transparent;
    }
    .field-panel {
        width: 100%;
        height: auto;
        border: tall $border;
        background: transparent;
        padding: 0 1;
    }
    #filter { background: transparent; }
    #table { background: transparent; }
    DataTable { background: transparent; }
    DataTable > .datatable--header { background: transparent; }
    DataTable > .datatable--cursor {
        background: $surface;
        color: $foreground;
    }
    #preview-overlay { background: transparent; }
    #preview-frame { background: transparent; }
    """
    + _SHARED_CSS
)

_STANDALONE_CSS = (
    f"""
    Screen {{
        layout: vertical;
        background: {NORD_BG};
    }}
    #top {{ height: auto; padding: 0 1; background: {NORD_BG}; }}
    #body {{
        height: 1fr;
        padding: 0 1 1 1;
        background: {NORD_BG};
    }}
    .field-panel {{
        width: 100%;
        height: auto;
        border: tall $border;
        background: {NORD_BG};
        padding: 0 1;
    }}
    #filter {{ background: {NORD_BG}; }}
    #table {{ background: {NORD_BG}; }}
    DataTable {{ background: {NORD_BG}; }}
    DataTable > .datatable--header {{ background: {NORD_BG}; }}
    DataTable > .datatable--odd-row,
    DataTable > .datatable--even-row {{
        background: {NORD_BG};
    }}
    DataTable > .datatable--cursor {{
        background: $panel;
        color: $foreground;
    }}
    #preview-overlay {{ background: {NORD_BG}; }}
    #preview-frame {{ background: {NORD_BG}; }}
    Static, Input, Vertical, VerticalScroll, Container {{
        background: {NORD_BG};
    }}
    """
    + _SHARED_CSS
)


def herdr_embedded() -> bool:
    return (
        os.environ.get("HERDR_GIT_TUI_EMBED") == "1"
        or os.environ.get("HERDR_ENV") == "1"
    )


def _build_app_css(*, in_herdr: bool) -> str:
    return _EMBEDDED_CSS if in_herdr else _STANDALONE_CSS


class GitTuiApp(App[None]):
    TITLE = "herdr-git-tui"
    theme = "nord"
    CSS = _build_app_css(in_herdr=False)

    BINDINGS: ClassVar[list[Binding]] = [
        Binding("q", "request_quit", "Quit", show=False, priority=True),
        Binding("escape", "handle_escape", "Quit", show=False, priority=True),
        Binding("tab", "toggle_focus", "Focus", show=False),
        Binding("ctrl+r", "reload", "Reload"),
        Binding("left", "view_prev", "Prev", show=False, priority=True),
        Binding("right", "view_next", "Next", show=False, priority=True),
        Binding("o", "open_browser", "Open", show=False, priority=True),
        Binding("p", "open_preview", "Preview", show=False),
        Binding("c", "checkout", "Checkout", show=False),
        Binding("d", "open_diff", "Diff", show=False),
        Binding("a", "approve", "Approve", show=False),
        Binding("s", "ci_toggle", "CI", show=False),
    ]

    def __init__(
        self,
        ctx: RepoContext | None,
        *,
        cwd: Path,
        repo_error: str | None = None,
        in_herdr: bool = False,
    ) -> None:
        super().__init__()
        self._in_herdr = in_herdr
        if not in_herdr:
            self.register_theme(NORD_SOLID_THEME)
            self.theme = "nord-solid"
        self.ctx = ctx
        self.cwd = cwd
        self.repo_error = repo_error
        self.tab = Tab.MRS
        self.rows: list[forge.Row] = []
        self.filtered: list[forge.Row] = []
        self.preview_open = False
        self.show_diff = False
        self._closing = False
        self._loading = False
        self._load_seq = 0

    def compose(self) -> ComposeResult:
        yield Static(id="top")
        with Vertical(id="body"):
            with Container(id="filter-panel", classes="field-panel"):
                yield SearchInput(placeholder="filter…", id="filter")
            with Container(id="list-panel", classes="field-panel"):
                yield DataTable(
                    id="table",
                    zebra_stripes=self._in_herdr,
                    cursor_type="row",
                )
        with Container(id="preview-overlay"):
            with Container(id="preview-frame"):
                yield Static("Esc / q close · o open in browser", id="preview-hint")
                yield Static(id="preview-header")
                yield VerticalScroll(Static(id="preview-body", expand=True, markup=False))

    def on_mount(self) -> None:
        if not self._in_herdr:
            self.screen.styles.background = NORD_BG
        self.query_one(DataTable).cursor_coordinate = (0, 0)
        self._refresh_chrome()
        self.action_focus_list()
        if self.repo_error:
            self._show_repo_error()
            return
        self.set_timer(0.05, self.action_reload)

    @property
    def _repo_ok(self) -> bool:
        return self.ctx is not None and not self.repo_error

    def _table_spec(self) -> list[tuple[str, int | None]]:
        if self.tab == Tab.MRS:
            return [
                ("", 3),
                ("title", 32),
                ("id", 6),
                ("ci", 10),
                ("approve", 12),
                ("author", 12),
                ("age", 4),
            ]
        if self.tab == Tab.CI:
            return [
                ("", 3),
                ("title", 28),
                ("status", 10),
                ("stage", 14),
                ("pipe", 8),
                ("age", 4),
            ]
        return [("", 3), ("title", 32), ("id", 6), ("label", 10), ("author", 12), ("age", 4)]

    @staticmethod
    def _fit(value: str, width: int) -> str:
        if len(value) <= width:
            return value
        if width < 2:
            return value[:width]
        return value[: width - 1] + "…"

    def _header_label(self, label: str, col_index: int) -> str | Text:
        if col_index >= 2 and label:
            return Text(label, justify="right", style="bold", no_wrap=True)
        return label

    @staticmethod
    def _semantic_style(value: str) -> str:
        v = (value or "").lower()
        if any(x in v for x in ("success", "passed", "approved", "ok")):
            return "green"
        if any(x in v for x in ("fail", "error", "canceled", "cancelled", "changes")):
            return "red"
        if any(x in v for x in ("run", "pend", "wait", "progress", "queued")):
            return "yellow"
        if any(x in v for x in ("skip",)):
            return "dim"
        return "cyan"

    @staticmethod
    def _approval_style(value: str) -> str:
        v = (value or "").strip().lower()
        if v in ("✓", "yes", "approved", "lgtm"):
            return "green"
        if v in ("✗", "no", "changes", "reject"):
            return "red"
        if v in ("—", "-", ""):
            return "dim"
        return "yellow"

    def _list_cell_style(self, cell_index: int, value: str) -> str:
        if self.tab == Tab.MRS:
            if cell_index == 1:
                return self._semantic_style(value)
            if cell_index == 2:
                return self._approval_style(value)
        if self.tab == Tab.CI and cell_index == 0:
            return self._semantic_style(value)
        return "dim"

    def _list_icon_style(self, row: forge.Row) -> str:
        if self.tab == Tab.ISSUES:
            return "cyan"
        if self.tab == Tab.CI and row.cells:
            return self._semantic_style(row.cells[0])
        if self.tab == Tab.MRS and len(row.cells) > 1:
            return self._semantic_style(row.cells[1])
        return "dim"

    def _text_cell(
        self,
        value: str,
        width: int,
        *,
        style: str | None = None,
        justify: str = "right",
    ) -> Text:
        text = Text(self._fit(str(value), width), justify=justify, no_wrap=True)
        if style:
            text.stylize(style)
        return text

    def _setup_table_columns(self, table: DataTable) -> None:
        table.clear(columns=True)
        for i, (label, width) in enumerate(self._table_spec()):
            table.add_column(self._header_label(label, i), width=width)

    def _row_values(self, row: forge.Row) -> tuple:
        spec = self._table_spec()
        icon_style = self._list_icon_style(row)
        values: list[str | Text] = [
            self._text_cell(row.icon, spec[0][1], style=icon_style, justify="center"),
            self._text_cell(row.title, spec[1][1], style="bold", justify="left"),
        ]
        for j, cell in enumerate(row.cells):
            col_index = j + 2
            width = spec[col_index][1]
            style = self._list_cell_style(j, cell)
            values.append(self._text_cell(cell, width, style=style, justify="right"))
        return tuple(values)

    def _set_preview_header(self, content: str, *, markup: bool = True) -> None:
        widget = self.query_one("#preview-header", Static)
        try:
            visual = Text.from_markup(content) if markup else Text(content)
            widget.update(visual)
        except Exception:
            widget.update(Text(rich_escape(content)))

    def _set_preview_body(
        self, content: str | RenderableType, *, markup: bool = False
    ) -> None:
        widget = self.query_one("#preview-body", Static)
        if not isinstance(content, str):
            widget.update(content)
            return
        try:
            visual = Text.from_markup(content) if markup else Text(content)
            widget.update(visual)
        except Exception:
            widget.update(Text(rich_escape(content)))

    def _clear_preview_panes(self) -> None:
        self._set_preview_header("")
        self._set_preview_body("")

    @classmethod
    def _color_meta(cls, label: str, value: str) -> str:
        color = cls._semantic_style(value)
        return f"[bold]{label}[/] [{color}]{rich_escape(value)}[/]"

    def _search_focused(self) -> bool:
        return self.focused is self.query_one("#filter", SearchInput)

    def _list_focused(self) -> bool:
        return self.focused is self.query_one(DataTable)

    def _can_navigate_views(self) -> bool:
        return self._list_focused() and not self.preview_open

    def _cancel_workers(self) -> None:
        self._load_seq += 1
        for worker in list(self.workers):
            worker.cancel()

    def _quit_clean(self) -> None:
        if self._closing:
            if self._in_herdr:
                hard_exit(0)
            restore_terminal()
            os._exit(0)
        self._closing = True
        self._cancel_workers()
        if self._in_herdr:
            hard_exit(0)
        restore_terminal()
        os._exit(0)

    def _show_loading_row(self) -> None:
        self._loading = True
        self.rows = []
        self.filtered = []
        table = self.query_one(DataTable)
        self._setup_table_columns(table)
        spec = self._table_spec()
        blanks = [
            self._text_cell("", spec[2 + i][1], style="dim")
            for i in range(len(self._table_spec()) - 2)
        ]
        table.add_row(
            self._text_cell("⟳", spec[0][1], style="yellow", justify="center"),
            self._text_cell("loading…", spec[1][1], style="dim italic", justify="left"),
            *blanks,
        )
        self._refresh_chrome()

    def _tab_chrome_label(self, name: str, key: Tab) -> Text:
        if self.tab == key:
            return Text(f"•{name}•", style="bold #88C0D0")
        return Text(name, style="dim")

    def _refresh_chrome(self) -> None:
        top = Text()
        if not self._repo_ok:
            msg = self.repo_error or "not a git repository"
            top.append(msg + "\n", style="bold red")
            top.append(str(self.cwd) + "\n", style="dim")
            top.append(
                "cd into a git clone (with origin) and reload, or quit with q",
                style="dim",
            )
            self.query_one("#top", Static).update(top)
            return
        mrs = self.ctx.mrs_label
        tab_names = [(mrs, Tab.MRS), ("CI", Tab.CI), ("Issues", Tab.ISSUES)]
        top.append("[ ", style="dim")
        for i, (name, key) in enumerate(tab_names):
            top.append_text(self._tab_chrome_label(name, key))
            if i < len(tab_names) - 1:
                top.append(" | ", style="dim")
        top.append(" ]  ")
        branch = f" · {self.ctx.branch}" if self.tab == Tab.CI else ""
        extra = ""
        if self.tab == Tab.MRS:
            extra = " · c checkout · d diff · a approve"
        elif self.tab == Tab.CI:
            extra = " · s stop/retry"
        load = " · loading…" if self._loading else f" · {len(self.filtered)} rows"
        top.append(f"{self.ctx.project}{branch}{load}\n")
        help_line = (
            f"Tab focus · ←/→ views · o open · p/Enter preview · ctrl+r reload{extra}"
        )
        top.append(help_line, style="dim")
        self.query_one("#top", Static).update(top)

    def _show_repo_error(self) -> None:
        self._loading = False
        self.rows = []
        self.filtered = []
        table = self.query_one(DataTable)
        self._setup_table_columns(table)
        spec = self._table_spec()
        msg = self.repo_error or "not a git repository"
        blanks = [
            self._text_cell("", spec[2 + i][1], style="dim")
            for i in range(len(spec) - 2)
        ]
        table.add_row(
            self._text_cell("!", spec[0][1], style="red", justify="center"),
            self._text_cell(msg, spec[1][1], style="yellow", justify="left"),
            *blanks,
        )
        self._refresh_chrome()

    def _selected_row(self) -> forge.Row | None:
        if self._loading:
            return None
        table = self.query_one(DataTable)
        if table.cursor_row is None or table.cursor_row < 0:
            return None
        if table.cursor_row >= len(self.filtered):
            return None
        return self.filtered[table.cursor_row]

    def _apply_filter(self) -> None:
        q = self.query_one(Input).value.strip().lower()
        if not q:
            self.filtered = list(self.rows)
        else:
            self.filtered = [r for r in self.rows if q in r.search_text()]
        table = self.query_one(DataTable)
        self._setup_table_columns(table)
        for r in self.filtered:
            table.add_row(*self._row_values(r), key=r.id)
        if self.filtered:
            table.move_cursor(row=0)
        self._refresh_chrome()

    @on(Input.Changed, "#filter")
    def _on_filter_changed(self) -> None:
        if not self._loading:
            self._apply_filter()

    def on_key(self, event: events.Key) -> None:
        if event.key == "enter" and self._list_focused() and not self.preview_open:
            self.action_open_preview()
            event.prevent_default()
            event.stop()

    def action_request_quit(self) -> None:
        if self.preview_open:
            self.action_close_preview()
            return
        if self._search_focused():
            return
        if self._list_focused():
            self._quit_clean()

    def action_handle_escape(self) -> None:
        if self.preview_open:
            self.action_close_preview()
        else:
            self._quit_clean()

    def action_close_preview(self) -> None:
        self.preview_open = False
        self.show_diff = False
        self._clear_preview_panes()
        self.query_one("#preview-overlay").remove_class("open")
        self.action_focus_list()

    def action_toggle_focus(self) -> None:
        if self.preview_open:
            return
        if self._search_focused():
            self.action_focus_list()
        else:
            self.query_one("#filter", SearchInput).focus()

    def action_focus_list(self) -> None:
        self.query_one(DataTable).focus()

    def action_view_next(self) -> None:
        if not self._can_navigate_views():
            return
        self._switch_view(self.tab.next())

    def action_view_prev(self) -> None:
        if not self._can_navigate_views():
            return
        self._switch_view(self.tab.prev())

    def _switch_view(self, tab: Tab) -> None:
        if not self._repo_ok:
            self.tab = tab
            self._refresh_chrome()
            self._show_repo_error()
            return
        self.tab = tab
        self.ctx = refresh_branch(self.ctx)
        self._refresh_chrome()
        self.action_reload()

    def action_reload(self) -> None:
        if not self._repo_ok:
            self._show_repo_error()
            return
        self.ctx = refresh_branch(self.ctx)
        for worker in self.workers:
            if worker.group == "fetch":
                worker.cancel()
        self._load_seq += 1
        seq = self._load_seq
        tab = self.tab
        ctx = self.ctx
        self._show_loading_row()
        self._fetch_rows(seq, tab, ctx)

    @work(thread=True, group="fetch")
    def _fetch_rows(self, seq: int, tab: Tab, ctx: RepoContext) -> None:
        try:
            if tab == Tab.MRS:
                rows = forge.fetch_mrs(ctx)
            elif tab == Tab.CI:
                rows = forge.fetch_ci(ctx)
            else:
                rows = forge.fetch_issues(ctx)
            err = None
        except RuntimeError as e:
            rows = []
            err = str(e)

        def finish() -> None:
            if self._closing or seq != self._load_seq:
                return
            self._loading = False
            self.rows = rows
            if err:
                self.notify(err, severity="error", timeout=8)
            self._apply_filter()
            self.action_focus_list()

        self.call_from_thread(finish)

    def action_open_browser(self) -> None:
        row = self._selected_row()
        if not row:
            return
        with open(os.devnull, "w") as devnull, contextlib.redirect_stderr(devnull):
            webbrowser.open(row.url)

    def _markdown_body(self, row: forge.Row) -> RenderableType:
        raw = row.raw
        body = (raw.get("description") or raw.get("body") or "").strip()
        if not body:
            return Text("(no description)", style="dim")
        return Markdown(body[:8000])

    def _format_preview_header(self, row: forge.Row) -> str:
        raw = row.raw
        if self.tab == Tab.MRS:
            src = raw.get("sourceBranch") or raw.get("headRefName") or "-"
            tgt = raw.get("targetBranch") or raw.get("baseRefName") or "-"
            if len(row.cells) >= 4:
                ci, apr, author, age = row.cells[1], row.cells[2], row.cells[3], row.cells[4]
            else:
                ci, apr, author, age = "-", "-", "-", "-"
            return (
                f"[bold]!{row.id}[/] {rich_escape(row.title)}\n"
                f"[dim]branch[/] {rich_escape(src)} → {rich_escape(tgt)}\n"
                f"{self._color_meta('ci', ci)}  {self._color_meta('approve', apr)}  "
                f"{self._color_meta('author', author)}  {self._color_meta('age', age)}\n"
                f"[dim underline]{rich_escape(row.url)}[/]"
            )
        if self.tab == Tab.CI:
            if len(row.cells) >= 4:
                st, stage, pipe, age = row.cells[0], row.cells[1], row.cells[2], row.cells[3]
            else:
                st, stage, pipe, age = "-", "-", "-", "-"
            return (
                f"[bold]{rich_escape(row.title)}[/]\n"
                f"{self._color_meta('status', st)}  {self._color_meta('stage', stage)}  "
                f"{self._color_meta('pipeline', pipe)}  {self._color_meta('age', age)}\n"
                f"[dim underline]{rich_escape(row.url)}[/]"
            )
        labels = ", ".join(raw.get("labels") or []) or "-"
        if len(row.cells) >= 4:
            iid, lab, author, age = row.cells[0], row.cells[1], row.cells[2], row.cells[3]
        else:
            iid, lab, author, age = f"#{row.id}", labels, "-", "-"
        return (
            f"[bold]{iid}[/] {rich_escape(row.title)}\n"
            f"{self._color_meta('label', lab)}  {self._color_meta('author', author)}  "
            f"{self._color_meta('age', age)}\n"
            f"[dim underline]{rich_escape(row.url)}[/]"
        )

    def _update_preview_content(self) -> None:
        row = self._selected_row()
        if not row:
            self._clear_preview_panes()
            return
        if self.show_diff and self.tab == Tab.MRS:
            self._set_preview_header(self._format_preview_header(row))
            self._set_preview_body("[dim]loading diff…[/]", markup=True)
            self._load_diff_async(row.id)
            return
        if self.tab == Tab.CI:
            self._set_preview_header(self._format_preview_header(row))
            self._set_preview_body(Text("loading logs…", style="dim italic"))
            self._load_ci_log_async(row)
            return
        self._set_preview_header(self._format_preview_header(row))
        self._set_preview_body(self._markdown_body(row))

    @work(thread=True, group="diff")
    def _load_diff_async(self, pr_id: str) -> None:
        try:
            text = forge.pr_diff(self.ctx, pr_id)
            content = ANSI_RE.sub("", text)[-12000:]
        except RuntimeError as e:
            content = str(e)

        def finish() -> None:
            if self._closing:
                return
            row = self._selected_row()
            if row:
                self._set_preview_header(self._format_preview_header(row))
            self._set_preview_body(content, markup=False)

        self.call_from_thread(finish)

    @work(thread=True, group="cilog")
    def _load_ci_log_async(self, row: forge.Row) -> None:
        try:
            log = forge.ci_job_log(self.ctx, row)
            body: str | RenderableType = log
        except RuntimeError as e:
            body = str(e)

        def finish() -> None:
            if self._closing or not self.preview_open:
                return
            self._set_preview_header(self._format_preview_header(row))
            self._set_preview_body(body, markup=False)

        self.call_from_thread(finish)

    def action_open_preview(self) -> None:
        if not self._list_focused() and not self.preview_open:
            return
        self.show_diff = False
        self.preview_open = True
        overlay = self.query_one("#preview-overlay")
        overlay.add_class("open")
        overlay.can_focus = True
        overlay.focus()
        self._update_preview_content()

    def action_open_diff(self) -> None:
        if self.tab != Tab.MRS:
            return
        self.show_diff = True
        if not self.preview_open:
            self.action_open_preview()
        else:
            self._update_preview_content()

    def action_checkout(self) -> None:
        if self.tab != Tab.MRS:
            return
        row = self._selected_row()
        if not row:
            return
        try:
            forge.pr_checkout(self.ctx, row.id)
        except RuntimeError as e:
            self.notify(str(e), severity="error", timeout=5)
            return
        self._quit_clean()

    def action_approve(self) -> None:
        if self.tab != Tab.MRS:
            return
        row = self._selected_row()
        if not row:
            return
        try:
            forge.pr_approve(self.ctx, row.id)
            self.notify(f"approved !{row.id}", timeout=3)
            self.action_reload()
        except RuntimeError as e:
            self.notify(str(e), severity="error", timeout=5)

    def action_ci_toggle(self) -> None:
        if self.tab != Tab.CI:
            return
        row = self._selected_row()
        if not row:
            return
        try:
            msg = forge.ci_job_toggle(self.ctx, row)
            self.notify(msg, timeout=3)
        except RuntimeError as e:
            self.notify(str(e), severity="error", timeout=6)


def run(argv: list[str]) -> None:
    try:
        import textual  # noqa: F401
    except ImportError:
        raise SystemExit(
            "textual is required: pipx install textual  (or pacman -S python-textual)"
        ) from None

    start: Path | None = None
    if argv:
        start = Path(argv[0])
    ctx, cwd, repo_error = try_resolve_repo(start)
    if ctx is not None:
        require_cli(ctx)
    in_herdr = herdr_embedded()
    GitTuiApp.CSS = _build_app_css(in_herdr=in_herdr)
    app = GitTuiApp(ctx, cwd=cwd, repo_error=repo_error, in_herdr=in_herdr)
    try:
        app.run(mouse=not in_herdr)
    except KeyboardInterrupt:
        if in_herdr:
            hard_exit(130)
        restore_terminal()
        raise SystemExit(130) from None
    finally:
        if not in_herdr:
            restore_terminal()
