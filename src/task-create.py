#!/usr/bin/env python3
"""Curses UI to create a Taskwarrior task (description / project / tags / longdescription)."""

from __future__ import annotations

import curses
import os
import re
import subprocess
import sys
import tempfile
from dataclasses import dataclass, field

# Color pairs (aligned with task-view)
C_TITLE = 1
C_KEY = 2
C_KEY_SEL = 3
C_MUTED = 4
C_VALUE = 5
C_VALUE_SEL = 6
C_STATUS = 7
C_BORDER = 8
C_MATCH = 9
C_OK = 10
C_ERR = 11

FIELDS = ("description", "project", "tags")
FOOTER_FORM = "j/k select  e/enter edit  c create  q quit"
FOOTER_EDIT = "type to edit  enter accept  esc cancel"
FOOTER_PROJECT = "type filter  ↑↓ move  enter pick/use typed  esc cancel"
FOOTER_TAGS = "type filter  ↑↓ move  space toggle  enter add/done  esc cancel"


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

    pair(C_TITLE, curses.COLOR_CYAN)
    pair(C_KEY, curses.COLOR_BLUE)
    pair(C_KEY_SEL, curses.COLOR_BLACK, curses.COLOR_CYAN)
    pair(C_MUTED, curses.COLOR_WHITE)
    pair(C_VALUE, curses.COLOR_WHITE)
    pair(C_VALUE_SEL, curses.COLOR_WHITE)
    pair(C_STATUS, curses.COLOR_BLACK, curses.COLOR_CYAN)
    pair(C_BORDER, curses.COLOR_WHITE)
    pair(C_MATCH, curses.COLOR_MAGENTA)
    pair(C_OK, curses.COLOR_GREEN)
    pair(C_ERR, curses.COLOR_RED)


def run_task(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["task", *args],
        capture_output=True,
        text=True,
        check=False,
    )


def load_projects() -> list[str]:
    result = run_task("rc.verbose=nothing", "_projects")
    return sorted({p for p in result.stdout.splitlines() if p.strip()})


def load_tags() -> list[str]:
    result = run_task("rc.verbose=nothing", "_unique", "tags")
    tags: set[str] = set()
    for line in result.stdout.splitlines():
        for part in line.split(","):
            part = part.strip()
            if part:
                tags.add(part)
    return sorted(tags)


def notify(msg: str) -> None:
    if subprocess.call(["which", "notify-send"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) == 0:
        subprocess.Popen(
            ["notify-send", "-a", "task-create", "task-create", msg],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )


def edit_longdescription() -> str:
    editor = os.environ.get("VISUAL") or os.environ.get("EDITOR") or "vim"
    terminal = os.environ.get("TERMINAL") or "st"
    with tempfile.NamedTemporaryFile(suffix=".md", delete=False, mode="w") as fh:
        path = fh.name
    try:
        if sys.stdin.isatty() and sys.stdout.isatty():
            subprocess.call([editor, path])
        else:
            subprocess.call([terminal, "-e", editor, path])
        with open(path, encoding="utf-8") as fh:
            return fh.read().rstrip("\n")
    finally:
        try:
            os.unlink(path)
        except OSError:
            pass


def create_task(description: str, project: str, tags: list[str], longdescription: str) -> str:
    # Modifiers MUST come before "--". Everything after "--" is description text
    # (so `project:foo` after "--" becomes part of the description).
    args = ["rc.confirmation=off", "add"]
    if project:
        args.append(f"project:{project}")
    for tag in tags:
        tag = tag.strip()
        if tag:
            args.append(f"+{tag}")
    args.extend(["--", description])

    result = run_task(*args)
    if result.returncode != 0:
        err = (result.stderr or result.stdout or "task add failed").strip()
        raise RuntimeError(err)

    id_result = run_task("rc.verbose=nothing", "+LATEST", "ids")
    task_id = (id_result.stdout or "").strip().split()[0] if id_result.stdout.strip() else ""
    if not task_id:
        # Fallback: parse "Created task N." from add output
        match = re.search(r"Created task (\d+)", result.stdout or "")
        task_id = match.group(1) if match else ""
    if not task_id:
        raise RuntimeError(f"created but could not resolve id ({result.stdout.strip()})")

    if longdescription:
        mod = run_task(
            "rc.verbose=nothing",
            "rc.confirmation=off",
            task_id,
            "modify",
            f"longdescription:{longdescription}",
        )
        if mod.returncode != 0:
            raise RuntimeError(f"created #{task_id} but failed to set longdescription")

    return task_id


def addstr(win: curses.window, y: int, x: int, text: str, attr: int = 0) -> None:
    try:
        height, width = win.getmaxyx()
        if y < 0 or y >= height or x >= width:
            return
        win.addstr(y, x, text[: max(0, width - x - 1)], attr)
    except curses.error:
        pass


@dataclass
class FormState:
    description: str = ""
    project: str = ""
    tags: list[str] = field(default_factory=list)
    field_idx: int = 0  # 0..2 fields, 3 = create action
    message: str = ""
    error: str = ""

    def value_for(self, name: str) -> str:
        if name == "description":
            return self.description
        if name == "project":
            return self.project
        if name == "tags":
            return ", ".join(self.tags) if self.tags else ""
        return ""


class TaskCreate:
    def __init__(self) -> None:
        self.state = FormState()
        self.projects = load_projects()
        self.all_tags = load_tags()
        self.mode = "form"  # form | edit | project | tags
        self.input = ""
        self.cursor = 0
        self.list_idx = 0
        self.list_offset = 0
        self.filtered: list[str] = []
        self.selected_tags: set[str] = set()
        self.done = False
        self.created_id: str | None = None

    # --- drawing -----------------------------------------------------------

    def _footer(self) -> str:
        if self.mode == "edit":
            return FOOTER_EDIT
        if self.mode == "project":
            return FOOTER_PROJECT
        if self.mode == "tags":
            return FOOTER_TAGS
        return FOOTER_FORM

    def draw(self, stdscr: curses.window) -> None:
        stdscr.erase()
        height, width = stdscr.getmaxyx()
        key_w = min(16, max(12, width // 5))
        sep = key_w + 1

        addstr(stdscr, 0, 0, " Create task", curses.color_pair(C_TITLE) | curses.A_BOLD)

        if self.mode == "form":
            self._draw_form(stdscr, height, width, key_w, sep)
        elif self.mode == "edit":
            self._draw_form(stdscr, height, width, key_w, sep)
            self._draw_input_line(stdscr, height, width, "description")
        elif self.mode == "project":
            self._draw_picker(stdscr, height, width, "project", self.filtered, single=True)
        elif self.mode == "tags":
            self._draw_picker(stdscr, height, width, "tags", self.filtered, single=False)

        status = self.state.error or self.state.message
        status_attr = curses.color_pair(C_ERR if self.state.error else C_STATUS)
        if not status:
            status = f" {self.state.description[:50] or '(no description yet)'}"
            status_attr = curses.color_pair(C_STATUS)
        addstr(stdscr, height - 2, 0, status.ljust(max(0, width - 1))[: width - 1], status_attr)
        addstr(
            stdscr,
            height - 1,
            0,
            self._footer().ljust(max(0, width - 1))[: width - 1],
            curses.color_pair(C_MUTED) | curses.A_DIM,
        )
        stdscr.refresh()

    def _draw_form(
        self, stdscr: curses.window, height: int, width: int, key_w: int, sep: int
    ) -> None:
        rows = [
            ("description", self.state.description),
            ("project", self.state.project),
            ("tags", ", ".join(self.state.tags) if self.state.tags else ""),
            ("create", "open editor for longdescription, then add task"),
        ]
        for i, (key, value) in enumerate(rows):
            y = 2 + i
            if y >= height - 3:
                break
            selected = self.state.field_idx == i
            label = f"▸ {key}" if selected else f"  {key}"
            key_attr = (
                curses.color_pair(C_KEY_SEL) | curses.A_BOLD
                if selected
                else curses.color_pair(C_KEY)
            )
            val_attr = (
                curses.color_pair(C_VALUE_SEL) | curses.A_BOLD
                if selected
                else curses.color_pair(C_VALUE)
            )
            if key == "create":
                val_attr = curses.color_pair(C_OK) | (curses.A_BOLD if selected else 0)

            addstr(stdscr, y, 0, label.ljust(key_w)[:key_w], key_attr)
            addstr(stdscr, y, sep, "│", curses.color_pair(C_BORDER) | curses.A_DIM)
            display = value if value else ("(required)" if key == "description" else "(optional)")
            muted = not value and key != "create"
            attr = curses.color_pair(C_MUTED) | curses.A_DIM if muted else val_attr
            addstr(stdscr, y, sep + 2, display, attr)

        hint_y = 2 + len(rows) + 1
        if hint_y < height - 3:
            addstr(
                stdscr,
                hint_y,
                0,
                "After create: $EDITOR opens for longdescription, then the task is added.",
                curses.color_pair(C_MUTED) | curses.A_DIM,
            )

    def _draw_input_line(self, stdscr: curses.window, height: int, width: int, label: str) -> None:
        _curs_set(1)
        line = f" {label}> {self.input}"
        addstr(stdscr, height - 3, 0, line.ljust(max(0, width - 1))[: width - 1], curses.color_pair(C_MATCH))
        try:
            stdscr.move(height - 3, min(width - 2, len(f" {label}> ") + self.cursor))
        except curses.error:
            pass

    def _draw_picker(
        self,
        stdscr: curses.window,
        height: int,
        width: int,
        kind: str,
        items: list[str],
        single: bool,
    ) -> None:
        _curs_set(1)
        prompt = f" {kind}> {self.input}"
        addstr(stdscr, 2, 0, prompt.ljust(max(0, width - 1))[: width - 1], curses.color_pair(C_TITLE) | curses.A_BOLD)

        if kind == "tags" and self.selected_tags:
            sel = ", ".join(sorted(self.selected_tags))
            addstr(stdscr, 3, 0, f" selected: {sel}"[: width - 1], curses.color_pair(C_OK))

        body_top = 5 if kind == "tags" else 4
        body = max(1, height - body_top - 2)
        if self.list_idx < self.list_offset:
            self.list_offset = self.list_idx
        if self.list_idx >= self.list_offset + body:
            self.list_offset = self.list_idx - body + 1

        if not items:
            addstr(
                stdscr,
                body_top,
                0,
                "  (no matches - enter uses what you typed)" if self.input else "  (empty list)",
                curses.color_pair(C_MUTED) | curses.A_DIM,
            )
        else:
            for row in range(body):
                idx = self.list_offset + row
                if idx >= len(items):
                    break
                item = items[idx]
                selected = idx == self.list_idx
                if single:
                    marker = "▸ " if selected else "  "
                else:
                    checked = item in self.selected_tags
                    marker = ("▸ " if selected else "  ") + ("[x] " if checked else "[ ] ")
                attr = (
                    curses.color_pair(C_KEY_SEL) | curses.A_BOLD
                    if selected
                    else curses.color_pair(C_VALUE)
                )
                addstr(stdscr, body_top + row, 0, f"{marker}{item}"[: width - 1], attr)

        try:
            stdscr.move(2, min(width - 2, len(f" {kind}> ") + self.cursor))
        except curses.error:
            pass

    # --- mode transitions --------------------------------------------------

    def open_edit_description(self) -> None:
        self.mode = "edit"
        self.input = self.state.description
        self.cursor = len(self.input)
        self.state.error = ""
        self.state.message = "editing description"

    def open_project_picker(self) -> None:
        self.mode = "project"
        self.input = self.state.project
        self.cursor = len(self.input)
        self._refilter_projects()
        self.state.error = ""
        self.state.message = "pick or type a project"

    def open_tags_picker(self) -> None:
        self.mode = "tags"
        self.input = ""
        self.cursor = 0
        self.selected_tags = set(self.state.tags)
        self._refilter_tags()
        self.state.error = ""
        self.state.message = "toggle tags, type to add new"

    def back_to_form(self) -> None:
        self.mode = "form"
        self.input = ""
        self.cursor = 0
        _curs_set(0)
        self.state.message = ""

    def _refilter_projects(self) -> None:
        q = self.input.lower()
        self.filtered = [p for p in self.projects if q in p.lower()] if q else list(self.projects)
        self.list_idx = min(self.list_idx, max(0, len(self.filtered) - 1))
        if not self.filtered:
            self.list_idx = 0
        self.list_offset = 0

    def _refilter_tags(self) -> None:
        q = self.input.lower()
        # show selected first, then the rest matching filter
        base = list(self.all_tags)
        for t in self.selected_tags:
            if t not in base:
                base.append(t)
        base = sorted(set(base))
        self.filtered = [t for t in base if q in t.lower()] if q else base
        self.list_idx = min(self.list_idx, max(0, len(self.filtered) - 1))
        if not self.filtered:
            self.list_idx = 0

    # --- input helpers -----------------------------------------------------

    def _handle_text_key(self, key: int) -> bool:
        """Mutate self.input/cursor. Return True if handled."""
        if key in (curses.KEY_BACKSPACE, 127, 8):
            if self.cursor > 0:
                self.input = self.input[: self.cursor - 1] + self.input[self.cursor :]
                self.cursor -= 1
            return True
        if key == curses.KEY_DC:
            if self.cursor < len(self.input):
                self.input = self.input[: self.cursor] + self.input[self.cursor + 1 :]
            return True
        if key == curses.KEY_LEFT:
            self.cursor = max(0, self.cursor - 1)
            return True
        if key == curses.KEY_RIGHT:
            self.cursor = min(len(self.input), self.cursor + 1)
            return True
        if key == curses.KEY_HOME:
            self.cursor = 0
            return True
        if key == curses.KEY_END:
            self.cursor = len(self.input)
            return True
        if 32 <= key <= 126:
            ch = chr(key)
            self.input = self.input[: self.cursor] + ch + self.input[self.cursor :]
            self.cursor += 1
            return True
        return False

    # --- actions -----------------------------------------------------------

    def activate_field(self) -> None:
        idx = self.state.field_idx
        if idx == 0:
            self.open_edit_description()
        elif idx == 1:
            self.open_project_picker()
        elif idx == 2:
            self.open_tags_picker()
        elif idx == 3:
            self.do_create()

    def do_create(self, stdscr: curses.window | None = None) -> None:
        if not self.state.description.strip():
            self.state.error = "description is required"
            self.state.field_idx = 0
            return

        self.state.error = ""
        self.state.message = "opening editor for longdescription..."
        if stdscr is not None:
            self.draw(stdscr)

        curses.def_prog_mode()
        curses.endwin()
        try:
            longdescription = edit_longdescription()
            task_id = create_task(
                self.state.description.strip(),
                self.state.project.strip(),
                list(self.state.tags),
                longdescription,
            )
        except Exception as exc:  # noqa: BLE001 - show in UI
            curses.reset_prog_mode()
            if stdscr is not None:
                stdscr.clear()
                stdscr.refresh()
            _curs_set(0)
            self.state.error = str(exc)
            self.state.message = ""
            return

        self.created_id = task_id
        notify(f"Created task #{task_id}")
        self.done = True
        # Stay in cooked mode; wrapper cleanup is fine after a clean endwin.

    # --- event loop --------------------------------------------------------

    def run(self, stdscr: curses.window) -> None:
        init_colors()
        _curs_set(0)
        stdscr.keypad(True)
        stdscr.timeout(-1)

        while not self.done:
            self.draw(stdscr)
            key = stdscr.getch()
            self.state.error = ""

            if self.mode == "form":
                self._on_form_key(key, stdscr)
            elif self.mode == "edit":
                self._on_edit_key(key)
            elif self.mode == "project":
                self._on_project_key(key)
            elif self.mode == "tags":
                self._on_tags_key(key)

    def _on_form_key(self, key: int, stdscr: curses.window) -> None:
        if key in (ord("q"), 27):
            self.done = True
        elif key in (ord("j"), curses.KEY_DOWN):
            self.state.field_idx = min(3, self.state.field_idx + 1)
        elif key in (ord("k"), curses.KEY_UP):
            self.state.field_idx = max(0, self.state.field_idx - 1)
        elif key in (ord("e"), ord("\n"), curses.KEY_ENTER, 10, 13):
            if self.state.field_idx == 3:
                self.do_create(stdscr)
            else:
                self.activate_field()
        elif key == ord("c"):
            self.do_create(stdscr)
        elif key == ord("g"):
            self.state.field_idx = 0
        elif key == ord("G"):
            self.state.field_idx = 3

    def _on_edit_key(self, key: int) -> None:
        if key == 27:
            self.back_to_form()
        elif key in (ord("\n"), curses.KEY_ENTER, 10, 13):
            self.state.description = self.input.strip()
            self.back_to_form()
            self.state.message = "description set" if self.state.description else "description cleared"
        else:
            self._handle_text_key(key)

    def _on_project_key(self, key: int) -> None:
        if key == 27:
            self.back_to_form()
        elif key == curses.KEY_UP:
            self.list_idx = max(0, self.list_idx - 1)
        elif key == curses.KEY_DOWN:
            if self.filtered:
                self.list_idx = min(len(self.filtered) - 1, self.list_idx + 1)
        elif key in (ord("\n"), curses.KEY_ENTER, 10, 13):
            # Highlighted match if any, otherwise use typed text as a new project.
            if self.filtered:
                self.state.project = self.filtered[self.list_idx]
            else:
                self.state.project = self.input.strip()
            self.back_to_form()
            self.state.message = f"project: {self.state.project or '(none)'}"
        else:
            if self._handle_text_key(key):
                self._refilter_projects()
                self.list_idx = 0

    def _on_tags_key(self, key: int) -> None:
        if key == 27:
            self.back_to_form()
        elif key == curses.KEY_UP:
            self.list_idx = max(0, self.list_idx - 1)
        elif key == curses.KEY_DOWN:
            if self.filtered:
                self.list_idx = min(len(self.filtered) - 1, self.list_idx + 1)
        elif key == ord(" "):
            if self.filtered and 0 <= self.list_idx < len(self.filtered):
                tag = self.filtered[self.list_idx]
                if tag in self.selected_tags:
                    self.selected_tags.discard(tag)
                else:
                    self.selected_tags.add(tag)
        elif key in (ord("\n"), curses.KEY_ENTER, 10, 13):
            typed = self.input.strip()
            if typed:
                # Enter with text: add typed tag, stay in picker
                self.selected_tags.add(typed)
                if typed not in self.all_tags:
                    self.all_tags = sorted(set(self.all_tags) | {typed})
                self.input = ""
                self.cursor = 0
                self._refilter_tags()
                self.state.message = f"added +{typed}"
            else:
                # Enter with empty input: confirm selection and return
                self.state.tags = sorted(self.selected_tags)
                self.back_to_form()
                self.state.message = f"tags: {', '.join(self.state.tags) or '(none)'}"
        else:
            if self._handle_text_key(key):
                self._refilter_tags()
                self.list_idx = 0


def ensure_tty() -> None:
    if sys.stdin.isatty() and sys.stdout.isatty():
        return
    terminal = os.environ.get("TERMINAL") or "st"
    os.execvp(terminal, [terminal, "-e", os.path.abspath(sys.argv[0]), *sys.argv[1:]])


def main() -> int:
    ensure_tty()
    app = TaskCreate()
    try:
        curses.wrapper(app.run)
    except curses.error:
        # Can happen after endwin + external $EDITOR; ignore if we already created.
        if not app.created_id:
            raise
    if app.created_id:
        print(f"Created task {app.created_id}")
        return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
