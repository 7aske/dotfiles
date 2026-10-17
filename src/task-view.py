#!/usr/bin/env python3
"""Terminal viewer for a single Taskwarrior task (two-column, colored)."""

from __future__ import annotations

import argparse
import curses
import json
import os
import re
import subprocess
import sys
import textwrap
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any

PRIORITY_KEYS = (
    "id",
    "uuid",
    "description",
    "status",
    "project",
    "priority",
    "tags",
    "due",
    "scheduled",
    "wait",
    "until",
    "start",
    "end",
    "entry",
    "modified",
    "urgency",
    "depends",
    "parent",
    "mask",
    "imask",
    "recur",
    "rtype",
)

DATE_RE = re.compile(r"^\d{8}T\d{6}Z$")
URL_RE = re.compile(r"https?://[^\s\[\]<>\"')]+")

# Color pair ids
C_TITLE = 1
C_KEY = 2
C_KEY_SEL = 3
C_PRI_H = 4
C_PRI_M = 5
C_PRI_L = 6
C_URG_LOW = 7
C_URG_MID = 8
C_URG_HIGH = 9
C_LINK = 10
C_MUTED = 11
C_VALUE = 12
C_VALUE_SEL = 13
C_STATUS = 14
C_MATCH = 15
C_BORDER = 16

FOOTER = "↑↓ scroll  {/} fields  / search  o open  e edit  r reload  q quit"


@dataclass
class Seg:
    text: str
    url: str | None = None


@dataclass
class FieldBlock:
    key: str
    lines: list[list[Seg]] = field(default_factory=list)


@dataclass
class Row:
    field_idx: int
    key_label: str  # empty for continuation lines
    segs: list[Seg]
    plain: str


def _curs_set(visibility: int) -> None:
    try:
        curses.curs_set(visibility)
    except curses.error:
        pass


def init_colors() -> None:
    curses.start_color()
    bg = curses.COLOR_BLACK
    try:
        curses.use_default_colors()
        bg = -1
    except curses.error:
        pass

    def pair(idx: int, fg: int, background: int | None = None) -> None:
        b = bg if background is None else background
        for candidate in (b, curses.COLOR_BLACK):
            try:
                curses.init_pair(idx, fg, candidate)
                return
            except (curses.error, ValueError):
                continue

    # Default background when the terminal supports it (bg=-1)
    pair(C_TITLE, curses.COLOR_CYAN)
    pair(C_KEY, curses.COLOR_BLUE)
    pair(C_KEY_SEL, curses.COLOR_BLACK, curses.COLOR_CYAN)
    pair(C_PRI_H, curses.COLOR_RED)
    pair(C_PRI_M, curses.COLOR_YELLOW)
    pair(C_PRI_L, curses.COLOR_CYAN)
    pair(C_URG_LOW, curses.COLOR_GREEN)
    pair(C_URG_MID, curses.COLOR_YELLOW)
    pair(C_URG_HIGH, curses.COLOR_RED)
    pair(C_LINK, curses.COLOR_CYAN)
    pair(C_MUTED, curses.COLOR_WHITE)
    pair(C_VALUE, curses.COLOR_WHITE)
    pair(C_VALUE_SEL, curses.COLOR_WHITE)
    pair(C_STATUS, curses.COLOR_BLACK, curses.COLOR_CYAN)
    pair(C_MATCH, curses.COLOR_MAGENTA)
    pair(C_BORDER, curses.COLOR_WHITE)


def run_task(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["task", *args],
        capture_output=True,
        text=True,
        check=False,
    )


def load_task(ident: str) -> dict[str, Any]:
    result = run_task(ident, "export", "rc.json.array=off", "rc.verbose=nothing")
    if result.returncode != 0:
        err = (result.stderr or result.stdout or "task export failed").strip()
        raise SystemExit(f"task-view: {err}")

    lines = [line for line in result.stdout.splitlines() if line.strip()]
    if not lines:
        raise SystemExit(f"task-view: no task matched '{ident}'")

    tasks = [json.loads(line) for line in lines]
    if len(tasks) > 1:
        raise SystemExit(
            f"task-view: filter matched {len(tasks)} tasks; pass an id or uuid"
        )
    return tasks[0]


def load_history(ident: str) -> list[str]:
    result = run_task(ident, "information", "rc.verbose=nothing")
    if result.returncode != 0:
        return []

    lines = result.stdout.splitlines()
    for i, line in enumerate(lines):
        if line.strip().startswith("Date") and "Modification" in line:
            return [l.rstrip() for l in lines[i:] if l.strip()]
    return []


def fmt_date(value: str) -> str:
    if not DATE_RE.match(value):
        return value
    try:
        dt = datetime.strptime(value, "%Y%m%dT%H%M%SZ").replace(tzinfo=timezone.utc)
        return dt.astimezone().strftime("%Y-%m-%d %H:%M:%S %Z")
    except ValueError:
        return value


def value_to_text(value: Any) -> str:
    if isinstance(value, list):
        if not value:
            return "[]"
        if all(isinstance(v, str) for v in value):
            return ", ".join(value)
        parts: list[str] = []
        for i, item in enumerate(value):
            if isinstance(item, dict):
                entry = fmt_date(str(item.get("entry", "")))
                desc = str(item.get("description", ""))
                parts.append(f"[{i}] {entry}\n{desc}".rstrip())
            else:
                parts.append(str(item))
        return "\n\n".join(parts)

    if isinstance(value, dict):
        return "\n".join(f"{k}: {value_to_text(v)}" for k, v in sorted(value.items()))

    if isinstance(value, str):
        return fmt_date(value)
    return str(value)


def segs_from_text(text: str) -> list[Seg]:
    segs: list[Seg] = []
    pos = 0
    for m in URL_RE.finditer(text):
        if m.start() > pos:
            segs.append(Seg(text[pos : m.start()]))
        url = m.group(0).rstrip(".,;:")
        segs.append(Seg(url, url))
        pos = m.start() + len(m.group(0))
        # keep trailing punctuation as plain text if stripped
        if len(url) < len(m.group(0)):
            segs.append(Seg(m.group(0)[len(url) :]))
            pos = m.end()
    if pos < len(text):
        segs.append(Seg(text[pos:]))
    return segs or [Seg("")]


def wrap_segs(segs: list[Seg], width: int) -> list[list[Seg]]:
    """Wrap segment list to lines without breaking URLs when possible."""
    if width < 8:
        width = 8
    lines: list[list[Seg]] = [[]]
    col = 0

    def push_piece(text: str, url: str | None) -> None:
        nonlocal col
        if not text:
            return
        while text:
            room = width - col
            if room <= 0:
                lines.append([])
                col = 0
                room = width
            if url and len(text) > room and col == 0:
                # URL longer than width: hard-split
                lines[-1].append(Seg(text[:width], url))
                text = text[width:]
                lines.append([])
                col = 0
                continue
            if url and len(text) > room:
                # wrap before URL
                lines.append([])
                col = 0
                continue
            chunk = text[:room]
            # prefer breaking at space for plain text
            if not url and len(text) > room:
                br = chunk.rfind(" ")
                if br > 0:
                    chunk = chunk[:br]
            if not chunk:
                chunk = text[:room]
            lines[-1].append(Seg(chunk, url))
            text = text[len(chunk) :]
            if text.startswith(" ") and not url:
                text = text.lstrip(" ")
            col += len(chunk)
            if text:
                lines.append([])
                col = 0

    for seg in segs:
        push_piece(seg.text, seg.url)
    return lines or [[Seg("")]]


def ordered_keys(task: dict[str, Any]) -> list[str]:
    head = [k for k in PRIORITY_KEYS if k in task]
    rest = sorted(k for k in task if k not in PRIORITY_KEYS and k != "annotations")
    if "annotations" in task:
        rest.append("annotations")
    return head + rest


def build_fields(task: dict[str, Any], history: list[str], value_width: int) -> list[FieldBlock]:
    fields: list[FieldBlock] = []
    for key in ordered_keys(task):
        text = value_to_text(task[key])
        line_segs: list[list[Seg]] = []
        for paragraph in text.split("\n"):
            line_segs.extend(wrap_segs(segs_from_text(paragraph), value_width))
        fields.append(FieldBlock(key=key, lines=line_segs or [[Seg("")]]))

    if history:
        hist_text = "\n".join(history)
        line_segs = []
        for paragraph in hist_text.split("\n"):
            line_segs.extend(wrap_segs(segs_from_text(paragraph), value_width))
        fields.append(FieldBlock(key="history", lines=line_segs or [[Seg("")]]))
    return fields


def flatten_rows(fields: list[FieldBlock]) -> list[Row]:
    rows: list[Row] = []
    for fi, fb in enumerate(fields):
        for li, segs in enumerate(fb.lines):
            plain = "".join(s.text for s in segs)
            label = fb.key if li == 0 else ""
            rows.append(Row(field_idx=fi, key_label=label, segs=segs, plain=plain))
    return rows


def priority_attr(value: str) -> int:
    v = value.strip().upper()
    if v == "H":
        return curses.color_pair(C_PRI_H) | curses.A_BOLD
    if v == "M":
        return curses.color_pair(C_PRI_M) | curses.A_BOLD
    if v == "L":
        return curses.color_pair(C_PRI_L) | curses.A_BOLD
    return curses.color_pair(C_VALUE)


def urgency_attr(value: str) -> int:
    try:
        n = float(value)
    except ValueError:
        return curses.color_pair(C_VALUE)
    if n >= 10:
        return curses.color_pair(C_URG_HIGH) | curses.A_BOLD
    if n >= 5:
        return curses.color_pair(C_URG_MID) | curses.A_BOLD
    return curses.color_pair(C_URG_LOW)


def open_url(url: str) -> None:
    if command_exists("xdg-open"):
        subprocess.Popen(
            ["xdg-open", url],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    elif command_exists("open"):
        subprocess.Popen(["open", url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def command_exists(name: str) -> bool:
    from shutil import which

    return which(name) is not None


def write_osc8(url: str | None) -> None:
    """Emit OSC 8 hyperlink start/end (no-op end when url is None)."""
    try:
        if url:
            sys.stdout.write(f"\033]8;;{url}\033\\")
        else:
            sys.stdout.write("\033]8;;\033\\")
        sys.stdout.flush()
    except Exception:
        pass


class TaskView:
    def __init__(self, ident: str) -> None:
        self.ident = ident
        self.task: dict[str, Any] = {}
        self.history: list[str] = []
        self.fields: list[FieldBlock] = []
        self.rows: list[Row] = []
        self.field_idx = 0
        self.offset = 0
        self.key_width = 16
        self.query = ""
        self.matches: list[int] = []  # field indices
        self.match_idx = -1
        self.message = ""
        # hit regions for mouse: (y, x_start, x_end, url)
        self.link_hits: list[tuple[int, int, int, str]] = []
        self._layout_cols = 0
        self.reload()

    def reload(self, width: int | None = None) -> None:
        self.task = load_task(self.ident)
        self.ident = str(self.task.get("uuid") or self.ident)
        self.history = load_history(self.ident)
        self._layout_cols = 0  # force rewrap
        self._rebuild(width)
        self.field_idx = min(self.field_idx, max(0, len(self.fields) - 1))
        if self.query:
            self._recompute_matches(keep_position=True)
        self.message = f"loaded {self.task.get('id', '?')}"

    def _rebuild(self, width: int | None = None) -> None:
        cols = width or getattr(curses, "COLS", 80) or 80
        if cols == self._layout_cols and self.fields:
            return
        self._layout_cols = cols
        self.key_width = min(24, max(12, cols // 4))
        # key | value █  — reserve 1 col for the right scrollbar
        value_width = max(20, cols - self.key_width - 6)
        self.fields = build_fields(self.task, self.history, value_width)
        self.rows = flatten_rows(self.fields)
        self._clamp_offset(getattr(curses, "LINES", 24) or 24)

    def _body_height(self, height: int) -> int:
        return max(1, height - 3)

    def _max_offset(self, height: int) -> int:
        return max(0, len(self.rows) - self._body_height(height))

    def _clamp_offset(self, height: int) -> None:
        self.offset = max(0, min(self._max_offset(height), self.offset))

    def _field_row_range(self, fi: int) -> tuple[int, int]:
        starts = [i for i, r in enumerate(self.rows) if r.field_idx == fi]
        if not starts:
            return 0, 0
        first = starts[0]
        last = first
        while last + 1 < len(self.rows) and self.rows[last + 1].field_idx == fi:
            last += 1
        return first, last

    def _jump_to_field(self, height: int) -> None:
        """Scroll so the selected field starts in view (field jump only)."""
        first, _last = self._field_row_range(self.field_idx)
        self.offset = first
        self._clamp_offset(height)

    def _sync_field_from_scroll(self) -> None:
        """Sidebar follows the field currently at the top of the content view."""
        if not self.rows:
            return
        idx = min(max(0, self.offset), len(self.rows) - 1)
        self.field_idx = self.rows[idx].field_idx

    def select_field(self, delta: int, height: int) -> None:
        if not self.fields:
            return
        new_idx = self.field_idx + delta
        if new_idx < 0 or new_idx >= len(self.fields):
            return
        self.field_idx = new_idx
        self._jump_to_field(height)
        self.message = self.fields[self.field_idx].key

    def scroll(self, delta: int, height: int) -> None:
        self.offset = max(0, min(self._max_offset(height), self.offset + delta))
        self._sync_field_from_scroll()

    def _recompute_matches(self, keep_position: bool = False) -> None:
        q = self.query.lower()
        self.matches = []
        if q:
            for i, fb in enumerate(self.fields):
                blob = fb.key.lower() + " " + " ".join(
                    "".join(s.text for s in line) for line in fb.lines
                )
                if q in blob:
                    self.matches.append(i)
        if not self.matches:
            self.match_idx = -1
            return
        if keep_position and self.match_idx >= 0:
            self.match_idx = min(self.match_idx, len(self.matches) - 1)
        else:
            self.match_idx = 0
        self.field_idx = self.matches[self.match_idx]

    def next_match(self, backward: bool, height: int) -> None:
        if not self.matches:
            self.message = "no matches" if self.query else "no search"
            return
        if backward:
            self.match_idx = (self.match_idx - 1) % len(self.matches)
        else:
            self.match_idx = (self.match_idx + 1) % len(self.matches)
        self.field_idx = self.matches[self.match_idx]
        self._jump_to_field(height)
        self.message = f"match {self.match_idx + 1}/{len(self.matches)}"

    def edit(self, stdscr: curses.window) -> None:
        curses.endwin()
        editor = os.environ.get("VISUAL") or os.environ.get("EDITOR") or "vim"
        env = os.environ.copy()
        env.setdefault("EDITOR", editor)
        env.setdefault("VISUAL", editor)
        subprocess.call(["task", self.ident, "edit"], env=env)
        stdscr.clear()
        stdscr.refresh()
        _curs_set(0)

    def task_open(self, stdscr: curses.window) -> None:
        uuid = str(self.task.get("uuid") or self.ident)
        curses.endwin()
        rc = subprocess.call(["task-open", uuid])
        stdscr.clear()
        stdscr.refresh()
        _curs_set(0)
        self.message = "opened" if rc == 0 else "task-open failed"

    def _value_attr(self, key: str, selected: bool) -> int:
        base = curses.color_pair(C_VALUE_SEL if selected else C_VALUE)
        if selected:
            base |= curses.A_BOLD
        if key == "priority":
            val = str(self.task.get("priority", ""))
            return priority_attr(val) | (curses.A_BOLD if selected else 0)
        if key == "urgency":
            val = str(self.task.get("urgency", ""))
            return urgency_attr(val) | (curses.A_BOLD if selected else 0)
        if key == "status":
            st = str(self.task.get("status", "")).lower()
            if st == "completed":
                return curses.color_pair(C_MUTED) | curses.A_DIM
            if st == "pending":
                return curses.color_pair(C_URG_LOW) | (curses.A_BOLD if selected else 0)
        return base

    def _supports_osc8(self) -> bool:
        term = os.environ.get("TERM", "") + os.environ.get("TERM_PROGRAM", "")
        return any(
            t in term.lower()
            for t in ("kitty", "foot", "wezterm", "ghostty", "iterm", "vscode")
        )

    def _add_segs(
        self,
        stdscr: curses.window,
        y: int,
        x: int,
        max_x: int,
        segs: list[Seg],
        attr: int,
    ) -> None:
        col = x
        use_osc8 = self._supports_osc8()
        for seg in segs:
            text = seg.text
            while text and col < max_x:
                room = max_x - col
                chunk = text[:room]
                text = text[room:]
                if seg.url:
                    link_attr = curses.color_pair(C_LINK) | curses.A_UNDERLINE | curses.A_BOLD
                    try:
                        if use_osc8:
                            stdscr.move(y, col)
                            write_osc8(seg.url)
                            stdscr.addstr(chunk, link_attr)
                            write_osc8(None)
                        else:
                            stdscr.addstr(y, col, chunk, link_attr)
                    except curses.error:
                        return
                    self.link_hits.append((y, col, col + len(chunk), seg.url))
                else:
                    try:
                        stdscr.addstr(y, col, chunk, attr)
                    except curses.error:
                        return
                col += len(chunk)

    def _draw_scrollbar(self, stdscr: curses.window, body_top: int, body: int, sb_x: int) -> None:
        """Right-edge scrollbar for total content scroll (not UDA index)."""
        total = len(self.rows)
        track_attr = curses.color_pair(C_BORDER) | curses.A_DIM
        thumb_attr = curses.color_pair(C_TITLE) | curses.A_BOLD

        if total <= 0 or body <= 0:
            return

        if total <= body:
            for i in range(body):
                try:
                    stdscr.addstr(body_top + i, sb_x, "│", track_attr)
                except curses.error:
                    pass
            return

        thumb = max(1, (body * body) // total)
        thumb = min(thumb, body)
        max_off = max(1, total - body)
        thumb_pos = int(round((body - thumb) * self.offset / max_off))
        thumb_pos = max(0, min(body - thumb, thumb_pos))

        for i in range(body):
            on_thumb = thumb_pos <= i < thumb_pos + thumb
            ch = "█" if on_thumb else "│"
            attr = thumb_attr if on_thumb else track_attr
            try:
                stdscr.addstr(body_top + i, sb_x, ch, attr)
            except curses.error:
                pass

    def draw(self, stdscr: curses.window) -> None:
        stdscr.erase()
        self.link_hits = []
        height, width = stdscr.getmaxyx()
        self._rebuild(width)

        body_top = 1
        body_bot = height - 2
        body = max(1, body_bot - body_top)

        self._clamp_offset(height)

        # header
        tid = self.task.get("id", "?")
        desc = str(self.task.get("description", ""))
        status = str(self.task.get("status", ""))
        project = str(self.task.get("project", ""))
        pri = str(self.task.get("priority", ""))
        urg = self.task.get("urgency", "")
        header = f" #{tid}  {status}"
        if project:
            header += f"  ·  {project}"
        if pri:
            header += f"  ·  pri:{pri}"
        if urg != "":
            header += f"  ·  urg:{urg}"
        header = header[: max(0, width - 1)]
        try:
            stdscr.addstr(0, 0, header.ljust(width - 1), curses.color_pair(C_TITLE) | curses.A_BOLD)
        except curses.error:
            pass

        sep = self.key_width + 1
        sb_x = max(0, width - 2)  # right-edge scrollbar column
        content_max_x = max(sep + 2, sb_x - 1)

        for row_i in range(body):
            idx = self.offset + row_i
            y = body_top + row_i
            if idx >= len(self.rows):
                break
            row = self.rows[idx]
            selected = row.field_idx == self.field_idx
            matched = row.field_idx in self.matches

            # left key column
            key_text = (row.key_label or "")[: self.key_width]
            if selected and row.key_label:
                key_text = ("▸ " + row.key_label)[: self.key_width]
                key_attr = curses.color_pair(C_KEY_SEL) | curses.A_BOLD
            elif selected:
                key_attr = curses.color_pair(C_KEY_SEL)
                key_text = "▸"
            elif matched and row.key_label:
                key_attr = curses.color_pair(C_MATCH) | curses.A_BOLD
            elif row.key_label:
                key_attr = curses.color_pair(C_KEY)
            else:
                key_attr = curses.color_pair(C_MUTED) | curses.A_DIM

            try:
                stdscr.addstr(y, 0, key_text.ljust(self.key_width)[: self.key_width], key_attr)
                # left separator stays neutral (not selection-colored)
                stdscr.addstr(y, sep, "│", curses.color_pair(C_BORDER) | curses.A_DIM)
            except curses.error:
                pass

            # value column (stops before the scrollbar)
            key = self.fields[row.field_idx].key if self.fields else ""
            val_attr = self._value_attr(key, selected)
            if matched and not selected:
                val_attr = curses.color_pair(C_MATCH)
            self._add_segs(stdscr, y, sep + 2, content_max_x, row.segs, val_attr)

        self._draw_scrollbar(stdscr, body_top, body, sb_x)

        # status + footer
        cur_key = self.fields[self.field_idx].key if self.fields else ""
        status_line = f" {cur_key}  ·  {self.offset + 1}-{min(self.offset + body, len(self.rows))}/{len(self.rows)}  ·  {len(self.fields)} fields"
        if self.query:
            status_line += f"  ·  /{self.query} ({len(self.matches)})"
        if self.message:
            status_line += f"  ·  {self.message}"
        # trim desc into status if room
        short = desc[:40]
        if short and width > 60:
            status_line = f" {short} │{status_line}"
        status_line = status_line[: max(0, width - 1)]
        footer = FOOTER[: max(0, width - 1)]
        try:
            stdscr.addstr(
                height - 2,
                0,
                status_line.ljust(width - 1),
                curses.color_pair(C_STATUS),
            )
            stdscr.addstr(
                height - 1,
                0,
                footer.ljust(width - 1),
                curses.color_pair(C_MUTED) | curses.A_DIM,
            )
        except curses.error:
            pass
        stdscr.refresh()

    def prompt_search(self, stdscr: curses.window) -> None:
        curses.echo()
        _curs_set(1)
        height, width = stdscr.getmaxyx()
        stdscr.addstr(height - 1, 0, " " * max(0, width - 1))
        stdscr.addstr(height - 1, 0, "/")
        stdscr.refresh()
        try:
            raw = stdscr.getstr(height - 1, 1, max(1, width - 2))
            query = raw.decode("utf-8", errors="replace")
        except Exception:
            query = self.query
        curses.noecho()
        _curs_set(0)
        self.query = query
        self._recompute_matches()
        if self.query and not self.matches:
            self.message = "no matches"
        elif self.query:
            self.field_idx = self.matches[self.match_idx]
            self.message = f"match 1/{len(self.matches)}"
        else:
            self.message = "search cleared"

    def handle_mouse(self) -> None:
        try:
            _, mx, my, _, bstate = curses.getmouse()
        except curses.error:
            return
        if not (bstate & curses.BUTTON1_CLICKED or bstate & curses.BUTTON1_PRESSED):
            return
        for y, x0, x1, url in self.link_hits:
            if my == y and x0 <= mx < x1:
                open_url(url)
                self.message = "opened link"
                return
        # click on a row selects its field
        height = curses.LINES
        body_top = 1
        if body_top <= my < height - 2:
            idx = self.offset + (my - body_top)
            if 0 <= idx < len(self.rows):
                self.field_idx = self.rows[idx].field_idx
                self.message = self.fields[self.field_idx].key

    def run(self, stdscr: curses.window) -> None:
        init_colors()
        _curs_set(0)
        stdscr.keypad(True)
        stdscr.timeout(-1)
        try:
            curses.mousemask(curses.ALL_MOUSE_EVENTS | curses.REPORT_MOUSE_POSITION)
            curses.mouseinterval(0)
        except curses.error:
            pass

        while True:
            self.draw(stdscr)
            key = stdscr.getch()
            height = curses.LINES
            self.message = ""

            if key in (ord("q"), 27):
                break
            if key == curses.KEY_MOUSE:
                self.handle_mouse()
            elif key in (ord("}"), ord("]")):
                # Shift+] is } ; also accept ] — jump fields, no wrap
                self.select_field(1, height)
            elif key in (ord("{"), ord("[")):
                self.select_field(-1, height)
            elif key in (ord("j"), curses.KEY_DOWN, curses.KEY_RIGHT):
                # arrows / j/k scroll content; sidebar follows
                self.scroll(1, height)
            elif key in (ord("k"), curses.KEY_UP, curses.KEY_LEFT):
                self.scroll(-1, height)
            elif key in (ord("d"), 4):
                self.scroll(max(1, (height - 3) // 2), height)
            elif key in (ord("u"), 21):
                self.scroll(-max(1, (height - 3) // 2), height)
            elif key in (ord("f"), curses.KEY_NPAGE, 6):
                self.scroll(max(1, height - 3), height)
            elif key in (ord("b"), curses.KEY_PPAGE, 2):
                self.scroll(-max(1, height - 3), height)
            elif key == ord("g"):
                self.offset = 0
                self._sync_field_from_scroll()
            elif key == ord("G"):
                self.offset = max(0, len(self.rows) - max(1, height - 3))
                self._sync_field_from_scroll()
            elif key == ord("/"):
                self.prompt_search(stdscr)
                self._jump_to_field(height)
            elif key == ord("n"):
                self.next_match(False, height)
            elif key == ord("N"):
                self.next_match(True, height)
            elif key == ord("e"):
                self.edit(stdscr)
                self.reload()
            elif key == ord("o"):
                self.task_open(stdscr)
            elif key == ord("r"):
                self.reload()
            elif key == curses.KEY_RESIZE:
                self._layout_cols = 0
                self.reload()


def plain_print(task: dict[str, Any], history: list[str], width: int = 100) -> None:
    key_w = 18
    fields = build_fields(task, history, max(20, width - key_w - 3))
    print(f"#{task.get('id', '?')}  {task.get('description', '')}")
    print()
    for fb in fields:
        for i, segs in enumerate(fb.lines):
            label = fb.key.ljust(key_w) if i == 0 else " " * key_w
            val = "".join(s.text for s in segs)
            print(f"{label}│ {val}")
        print()


def main() -> None:
    parser = argparse.ArgumentParser(description="View a Taskwarrior task in the terminal")
    parser.add_argument("task", help="Task id or uuid")
    args = parser.parse_args()

    if not sys.stdout.isatty():
        task = load_task(args.task)
        history = load_history(str(task.get("uuid") or args.task))
        plain_print(task, history)
        return

    def _run(stdscr: curses.window) -> None:
        view = TaskView(args.task)
        view.run(stdscr)

    curses.wrapper(_run)


if __name__ == "__main__":
    main()
