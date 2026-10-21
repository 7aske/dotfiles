#!/usr/bin/env python3
"""herdr-git-tui — MRs/PRs, CI (current branch), and issues for the herdr workspace repo."""

from __future__ import annotations

import os
import sys
from pathlib import Path

# Herdr popups share the pane TTY with the compositor; Kitty key protocol + alt screen
# can brick input if Textual shutdown hangs — disable before Textual loads.
# Popup / embedded TTY: avoid Kitty keyboard protocol sticking after exit.
os.environ.setdefault("TEXTUAL_DISABLE_KITTY_KEY", "1")

_SHARE = Path.home() / ".local/share/herdr-git-tui"
_HERE = Path(__file__).resolve().parent
if os.environ.get("HERDR_GIT_TUI_DEV") == "1" and (_HERE / "herdr_git_tui").is_dir():
    sys.path.insert(0, str(_HERE))
elif _SHARE.is_dir():
    sys.path.insert(0, str(_SHARE))
elif (_HERE / "herdr_git_tui").is_dir():
    sys.path.insert(0, str(_HERE))

from herdr_git_tui.app import run  # noqa: E402

if __name__ == "__main__":
    run(sys.argv[1:])
