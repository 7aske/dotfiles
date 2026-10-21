"""Restore the terminal after Textual (critical for Herdr popups)."""

from __future__ import annotations

import os
import sys
import termios
import tty

# Kitty keyboard protocol + alt screen + mouse/bracketed paste + cursor shape off.
_RESET_SEQUENCES = (
    "\x1b[?1049l"
    "\x1b[?25h"
    "\x1b[0 q"
    "\x1b[<u"
    "\x1b[?1004l"
    "\x1b[?2004l"
    "\x1b[?1000l\x1b[?1002l\x1b[?1003l\x1b[?1006l"
    "\x1b[0m"
)


def restore_terminal() -> None:
    fd = sys.stdin.fileno()
    try:
        attrs = termios.tcgetattr(fd)
        attrs[tty.LFLAG] |= termios.ECHO | termios.ICANON | termios.ISIG
        attrs[tty.IFLAG] |= termios.ICRNL
        termios.tcsetattr(fd, termios.TCSADRAIN, attrs)
    except (termios.error, OSError):
        pass
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.write(_RESET_SEQUENCES)
            stream.flush()
        except OSError:
            pass


def hard_exit(code: int = 0) -> None:
    """Exit immediately; do not wait on Textual async shutdown (avoids Herdr pane lock)."""
    restore_terminal()
    os._exit(code)
