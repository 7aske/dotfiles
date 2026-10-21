"""Git repo and herdr workspace context."""

from __future__ import annotations

import json
import subprocess
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import urlparse


@dataclass(frozen=True)
class RepoContext:
    root: Path
    forge: str  # github | gitlab
    host: str
    project: str
    branch: str

    @property
    def mrs_label(self) -> str:
        return "PRs" if self.forge == "github" else "MRs"

    @property
    def repo_url(self) -> str:
        return f"https://{self.host}/{self.project}"

    @property
    def repo_slug(self) -> str:
        return f"{self.host}/{self.project}"

    @property
    def gh_repo_path(self) -> str:
        return self.project


def _run(cmd: list[str], *, cwd: Path | None = None, check: bool = True) -> str:
    p = subprocess.run(cmd, cwd=cwd, text=True, capture_output=True)
    if check and p.returncode != 0:
        err = (p.stderr or p.stdout or "").strip()
        raise RuntimeError(err or f"command failed: {cmd[0]}")
    return p.stdout


def herdr_cwd() -> Path | None:
    try:
        panes = json.loads(_run(["herdr", "pane", "list"], check=True))
        ws_data = json.loads(_run(["herdr", "workspace", "list"], check=True))
    except (FileNotFoundError, json.JSONDecodeError, RuntimeError):
        return None
    workspaces = ws_data.get("result", {}).get("workspaces", [])
    focused_ws = next((w["workspace_id"] for w in workspaces if w.get("focused")), "")
    pane_list = panes.get("result", {}).get("panes", [])
    ordered = [p for p in pane_list if p.get("focused")] + [
        p for p in pane_list if p.get("workspace_id") == focused_ws
    ]
    for p in ordered:
        cwd = p.get("foreground_cwd") or p.get("cwd")
        if cwd:
            return Path(cwd)
    return None


def _parse_remote_url(url: str) -> tuple[str, str]:
    url = url.strip()
    if "://" in url:
        parsed = urlparse(url)
        host = (parsed.hostname or "").split(":")[0]
        project = parsed.path.strip("/").removesuffix(".git")
        return host, project
    if "@" in url and ":" in url:
        rest = url.split("@", 1)[1]
        host, project = rest.split(":", 1)
        project = project.removesuffix(".git").strip("/")
        return host, project
    raise ValueError(f"unusable remote url: {url}")


def try_resolve_repo(start: Path | None) -> tuple[RepoContext | None, Path, str | None]:
    """Resolve repo context, or return (None, cwd, message) when not in a git tree."""
    cwd = start or herdr_cwd() or Path.cwd()
    probe = start if start is not None else cwd
    p = subprocess.run(
        ["git", "-C", str(probe), "rev-parse", "--show-toplevel"],
        text=True,
        capture_output=True,
    )
    if p.returncode != 0:
        return None, cwd, "current folder is not a git repository"
    try:
        return resolve_repo(probe), cwd, None
    except (RuntimeError, ValueError) as e:
        return None, cwd, str(e)


def resolve_repo(start: Path | None) -> RepoContext:
    start = start or herdr_cwd() or Path.cwd()
    root = Path(_run(["git", "-C", str(start), "rev-parse", "--show-toplevel"]).strip())
    try:
        remote = _run(["git", "-C", str(root), "remote", "get-url", "origin"]).strip()
    except RuntimeError:
        remote = _run(["git", "-C", str(root), "remote", "-v"]).split()[1]
    host, project = _parse_remote_url(remote)
    forge = "github" if "github" in host else "gitlab"
    branch = _run(["git", "-C", str(root), "rev-parse", "--abbrev-ref", "HEAD"]).strip()
    return RepoContext(root=root, forge=forge, host=host, project=project, branch=branch)


def refresh_branch(ctx: RepoContext) -> RepoContext:
    branch = _run(["git", "-C", str(ctx.root), "rev-parse", "--abbrev-ref", "HEAD"]).strip()
    return RepoContext(
        root=ctx.root,
        forge=ctx.forge,
        host=ctx.host,
        project=ctx.project,
        branch=branch,
    )


def require_cli(ctx: RepoContext) -> None:
    tool = "gh" if ctx.forge == "github" else "glab"
    try:
        subprocess.run([tool, "--version"], capture_output=True, check=True)
    except FileNotFoundError:
        raise RuntimeError(f"{tool}: command not found") from None
