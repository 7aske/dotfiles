"""Fetch MRs, CI jobs, and issues via gh / glab."""

from __future__ import annotations

import json
import re
import subprocess
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any

from .repo import RepoContext


ISSUE_ICON = "◆"


def status_icon(status: str | None) -> str:
    s = (status or "").upper()
    if s in ("SUCCESS", "PASSED", "OK"):
        return "✓"
    if s in ("FAILED", "FAILURE", "ERROR"):
        return "✗"
    if s in ("CANCELED", "CANCELLED"):
        return "⊗"
    if s == "SKIPPED":
        return "⊘"
    if s in ("RUNNING", "IN_PROGRESS", "PENDING", "CREATED", "WAITING", "QUEUED", "WAITING_FOR_RESOURCE"):
        return "⟳"
    return "○"


@dataclass
class Row:
    id: str
    title: str
    url: str
    icon: str = "○"
    cells: list[str] = field(default_factory=list)
    subtitle: str = ""
    raw: dict[str, Any] = field(default_factory=dict)

    def search_text(self) -> str:
        parts = [self.id, self.title, *self.cells, self.subtitle]
        return " ".join(parts).lower()


_SUBPROCESS_TIMEOUT = 45


def _run_json(cmd: list[str], *, cwd: str | None = None) -> Any:
    p = subprocess.run(
        cmd, cwd=cwd, text=True, capture_output=True, timeout=_SUBPROCESS_TIMEOUT
    )
    if p.returncode != 0:
        err = (p.stderr or p.stdout or "").strip()
        raise RuntimeError(err or cmd[0])
    return json.loads(p.stdout or "null")


def _run(cmd: list[str], *, cwd: str | None = None) -> None:
    p = subprocess.run(
        cmd, cwd=cwd, text=True, capture_output=True, timeout=_SUBPROCESS_TIMEOUT
    )
    if p.returncode != 0:
        raise RuntimeError((p.stderr or p.stdout or cmd[0]).strip())


def _ago(iso: str | None) -> str:
    if not iso:
        return "-"
    s = iso.replace("Z", "+00:00")
    if "." in s:
        head, tail = s.split(".", 1)
        if "+" not in tail[:8]:
            s = head + "+00:00"
    try:
        dt = datetime.fromisoformat(s.replace("Z", "+00:00"))
    except ValueError:
        return "-"
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    delta = datetime.now(timezone.utc) - dt.astimezone(timezone.utc)
    sec = int(delta.total_seconds())
    if sec < 3600:
        return f"{sec // 60}m"
    if sec < 86400:
        return f"{sec // 3600}h"
    return f"{sec // 86400}d"


def _gh_rollups(statuses: list[str]) -> str | None:
    if not statuses:
        return None
    up = [s.upper() for s in statuses if s]
    if not up:
        return None
    if any(s in up for s in ("FAILURE", "ERROR", "CANCELLED", "TIMED_OUT", "ACTION_REQUIRED")):
        return "FAILED"
    if any(s in up for s in ("PENDING", "QUEUED", "IN_PROGRESS", "EXPECTED", "WAITING")):
        return "RUNNING"
    return "SUCCESS"


def _gitlab_approval(n: dict[str, Any]) -> str:
    if n.get("approved"):
        return "approved"
    left = n.get("approvalsLeft")
    if left is not None and left == 0:
        return "approved"
    status = n.get("detailedMergeStatus") or "-"
    return str(status).lower().replace("_", " ")


def _github_approval(n: dict[str, Any]) -> str:
    d = n.get("reviewDecision") or "-"
    return str(d).lower().replace("_", " ")


def _mr_ci_apr(ctx: RepoContext, n: dict[str, Any]) -> tuple[str, str]:
    if ctx.forge == "gitlab":
        ci = (n.get("headPipeline") or {}).get("status") or "-"
        apr = _gitlab_approval(n)
    else:
        roll = [
            x.get("conclusion") or x.get("state") or x.get("status") or ""
            for x in n.get("statusCheckRollup") or []
        ]
        ci = _gh_rollups(roll) or "-"
        apr = _github_approval(n)
    return ci, apr


def fetch_mrs(ctx: RepoContext) -> list[Row]:
    if ctx.forge == "gitlab":
        q = """
        query($p: ID!) {
          project(fullPath: $p) {
            mergeRequests(state: opened, sort: UPDATED_DESC, first: 100) {
              nodes {
                iid title description draft webUrl sourceBranch targetBranch updatedAt
                detailedMergeStatus approved approvalsLeft
                author { username }
                headPipeline { status }
              }
            }
          }
        }"""
        data = _run_json(
            ["glab", "api", "graphql", "--hostname", ctx.host, "-f", f"p={ctx.project}", "-f", f"query={q}"]
        )
        if data.get("errors"):
            raise RuntimeError("; ".join(e.get("message", "") for e in data["errors"]))
        nodes = data["data"]["project"]["mergeRequests"]["nodes"]
        rows: list[Row] = []
        for n in nodes:
            iid = str(n["iid"])
            author = n["author"]["username"]
            ci, apr = _mr_ci_apr(ctx, n)
            age = _ago(n["updatedAt"])
            rows.append(
                Row(
                    id=iid,
                    title=n["title"],
                    url=n["webUrl"],
                    icon=status_icon(ci),
                    cells=[f"!{iid}", ci, apr, f"@{author}", age],
                    raw=n,
                )
            )
        return rows

    data = _run_json(
        [
            "gh",
            "pr",
            "list",
            "-R",
            ctx.repo_slug,
            "--state",
            "open",
            "--limit",
            "30",
            "--json",
            "number,title,body,url,updatedAt,author,statusCheckRollup,reviewDecision",
        ]
    )
    rows = []
    for n in data:
        num = str(n["number"])
        pipe = _gh_rollups(
            [
                x.get("conclusion") or x.get("state") or x.get("status") or ""
                for x in n.get("statusCheckRollup") or []
            ]
        )
        author = n["author"]["login"]
        ci, apr = _mr_ci_apr(ctx, n)
        age = _ago(n["updatedAt"])
        rows.append(
            Row(
                id=num,
                title=n["title"],
                url=n["url"],
                icon=status_icon(ci or pipe),
                cells=[f"!{num}", ci or pipe or "-", apr, f"@{author}", age],
                raw={**n, "body": n.get("body"), "pipeline": pipe, "ci": ci, "apr": apr},
            )
        )
    return rows


def _norm_job_status(raw: dict[str, Any]) -> str:
    st = (raw.get("status") or raw.get("conclusion") or "").upper()
    if st in ("FAILURE", "FAILED"):
        return "FAILED"
    if st in ("SUCCESS", "PASSED"):
        return "SUCCESS"
    if st in ("RUNNING", "IN_PROGRESS", "PENDING", "QUEUED", "CREATED", "WAITING"):
        return "RUNNING"
    return st or "PENDING"


def fetch_ci(ctx: RepoContext) -> list[Row]:
    if ctx.forge == "gitlab":
        q = """
        query($p: ID!, $ref: String!) {
          project(fullPath: $p) {
            pipelines(ref: $ref, first: 12) {
              nodes {
                iid status updatedAt
                jobs { nodes { id name status stage { name } webPath startedAt finishedAt } }
              }
            }
          }
        }"""
        data = _run_json(
            [
                "glab",
                "api",
                "graphql",
                "--hostname",
                ctx.host,
                "-f",
                f"p={ctx.project}",
                "-f",
                f"ref={ctx.branch}",
                "-f",
                f"query={q}",
            ]
        )
        if data.get("errors"):
            raise RuntimeError("; ".join(e.get("message", "") for e in data["errors"]))
        jobs: list[Row] = []
        for pl in data["data"]["project"]["pipelines"]["nodes"]:
            for j in pl["jobs"]["nodes"]:
                jid = j["webPath"].rstrip("/").split("/")[-1]
                updated = j.get("finishedAt") or j.get("startedAt") or pl["updatedAt"]
                stage = (j.get("stage") or {}).get("name") or "-"
                st = j["status"]
                age = _ago(updated)
                jobs.append(
                    Row(
                        id=jid,
                        title=j["name"],
                        url=f"https://{ctx.host}{j['webPath']}",
                        icon=status_icon(st),
                        cells=[st, stage, f"#{pl['iid']}", age],
                        raw={
                            **j,
                            "ref": ctx.branch,
                            "run_id": str(pl["iid"]),
                            "updated": updated,
                            "job_status": j["status"],
                        },
                    )
                )
        jobs.sort(key=lambda r: r.raw.get("updated") or "", reverse=True)
        return jobs[:80]

    runs = _run_json(
        [
            "gh",
            "run",
            "list",
            "-R",
            ctx.repo_slug,
            "--branch",
            ctx.branch,
            "--limit",
            "12",
            "--json",
            "databaseId",
        ]
    )
    jobs: list[Row] = []
    for run in runs:
        rid = str(run["databaseId"])
        chunk = _run_json(
            ["gh", "run", "view", rid, "-R", ctx.repo_slug, "--json", "jobs,workflowName,updatedAt,displayTitle"]
        )
        for j in chunk.get("jobs") or []:
            st = _norm_job_status(j)
            updated = j.get("completedAt") or j.get("startedAt") or chunk.get("updatedAt")
            jid = str(j["databaseId"])
            wf = chunk.get("workflowName", "workflow")
            age = _ago(updated)
            jobs.append(
                Row(
                    id=jid,
                    title=j["name"],
                    url=j["url"],
                    icon=status_icon(st),
                    cells=[st, wf, f"#{rid}", age],
                    raw={
                        **j,
                        "ref": ctx.branch,
                        "run_id": rid,
                        "updated": updated,
                        "run_title": chunk.get("displayTitle"),
                        "job_status": st,
                    },
                )
            )
    jobs.sort(key=lambda r: r.raw.get("updated") or "", reverse=True)
    return jobs[:80]


def fetch_issues(ctx: RepoContext) -> list[Row]:
    if ctx.forge == "gitlab":
        q = """
        query($p: ID!) {
          project(fullPath: $p) {
            issues(state: opened, sort: UPDATED_DESC, first: 100) {
              nodes {
                iid title description webUrl updatedAt
                author { username }
                labels { nodes { title } }
              }
            }
          }
        }"""
        data = _run_json(
            ["glab", "api", "graphql", "--hostname", ctx.host, "-f", f"p={ctx.project}", "-f", f"query={q}"]
        )
        if data.get("errors"):
            raise RuntimeError("; ".join(e.get("message", "") for e in data["errors"]))
        rows = []
        for n in data["data"]["project"]["issues"]["nodes"]:
            labels = [x["title"] for x in n.get("labels", {}).get("nodes", [])]
            iid = str(n["iid"])
            lab = labels[0] if labels else "-"
            rows.append(
                Row(
                    id=iid,
                    title=n["title"],
                    url=n["webUrl"],
                    icon=ISSUE_ICON,
                    cells=[f"#{iid}", lab, f"@{n['author']['username']}", _ago(n["updatedAt"])],
                    raw={**n, "labels": labels},
                )
            )
        return rows

    data = _run_json(
        [
            "gh",
            "issue",
            "list",
            "-R",
            ctx.repo_slug,
            "--state",
            "open",
            "--limit",
            "100",
            "--json",
            "number,title,body,url,updatedAt,author,labels",
        ]
    )
    rows = []
    for n in data:
        num = str(n["number"])
        labels = [lb.get("name", "") for lb in n.get("labels") or []]
        lab = labels[0] if labels else "-"
        rows.append(
            Row(
                id=num,
                title=n["title"],
                url=n["url"],
                icon=ISSUE_ICON,
                cells=[f"#{num}", lab, f"@{n['author']['login']}", _ago(n["updatedAt"])],
                raw={**n, "description": n.get("body"), "labels": labels},
            )
        )
    return rows


def ci_job_log(ctx: RepoContext, row: Row) -> str:
    """Fetch job log text (truncated). May block briefly on running jobs."""
    if ctx.forge == "gitlab":
        p = subprocess.run(
            ["glab", "ci", "trace", row.id, "-R", ctx.repo_slug],
            text=True,
            capture_output=True,
            timeout=_SUBPROCESS_TIMEOUT,
        )
        out = (p.stdout or "") + (p.stderr or "")
        if p.returncode != 0 and not out.strip():
            # REST trace endpoint fallback
            enc = ctx.project.replace("/", "%2F")
            p2 = subprocess.run(
                [
                    "glab",
                    "api",
                    f"projects/{enc}/jobs/{row.id}/trace",
                    "--hostname",
                    ctx.host,
                ],
                text=True,
                capture_output=True,
                timeout=_SUBPROCESS_TIMEOUT,
            )
            out = (p2.stdout or "") + (p2.stderr or "")
            if p2.returncode != 0 and not out.strip():
                raise RuntimeError(out.strip() or "failed to fetch job log")
    else:
        run_id = str(row.raw.get("run_id") or "")
        if not run_id:
            raise RuntimeError("missing workflow run id for job")
        p = subprocess.run(
            [
                "gh",
                "run",
                "view",
                run_id,
                "--job",
                row.id,
                "--log",
                "-R",
                ctx.repo_slug,
            ],
            text=True,
            capture_output=True,
            timeout=_SUBPROCESS_TIMEOUT,
        )
        out = (p.stdout or "") + (p.stderr or "")
        if p.returncode != 0:
            raise RuntimeError(out.strip() or "failed to fetch job log")
    out = re.sub(r"\x1b\[[0-9;]*m", "", out)
    if len(out) > 48000:
        out = out[-48000:]
        out = f"…(truncated)\n{out}"
    return out or "(empty log)"


def pr_diff(ctx: RepoContext, pr_id: str) -> str:
    if ctx.forge == "gitlab":
        p = subprocess.run(
            ["glab", "mr", "diff", pr_id, "-R", ctx.repo_slug, "--color=never"],
            cwd=ctx.root,
            text=True,
            capture_output=True,
            timeout=_SUBPROCESS_TIMEOUT,
        )
    else:
        p = subprocess.run(
            ["gh", "pr", "diff", pr_id, "-R", ctx.repo_slug, "--color=never"],
            cwd=ctx.root,
            text=True,
            capture_output=True,
            timeout=_SUBPROCESS_TIMEOUT,
        )
    if p.returncode != 0:
        raise RuntimeError((p.stderr or p.stdout or "diff failed").strip())
    return p.stdout


def pr_checkout(ctx: RepoContext, pr_id: str) -> None:
    if ctx.forge == "gitlab":
        cmd = ["glab", "mr", "checkout", pr_id]
    else:
        cmd = ["gh", "pr", "checkout", pr_id]
    _run(cmd, cwd=str(ctx.root))


def pr_approve(ctx: RepoContext, pr_id: str) -> None:
    if ctx.forge == "gitlab":
        _run(["glab", "mr", "approve", pr_id, "-R", ctx.repo_slug])
    else:
        _run(["gh", "pr", "review", pr_id, "-R", ctx.repo_slug, "--approve"])


def _job_running(raw: dict[str, Any], forge: str) -> bool:
    if forge == "gitlab":
        st = (raw.get("status") or raw.get("job_status") or "").upper()
        return st in ("RUNNING", "PENDING", "CREATED", "WAITING_FOR_RESOURCE", "PREPARING")
    st = _norm_job_status(raw)
    return st == "RUNNING"


def ci_job_toggle(ctx: RepoContext, row: Row) -> str:
    """Cancel a running job or retry a finished one. Returns a short status message."""
    raw = row.raw
    running = _job_running(raw, ctx.forge)
    if ctx.forge == "gitlab":
        if running:
            _run(["glab", "ci", "cancel", "job", row.id, "-R", ctx.repo_slug])
            return "job cancel requested"
        _run(["glab", "ci", "retry", row.id, "-R", ctx.repo_slug])
        return "job retry requested"

    repo = ctx.gh_repo_path
    if running:
        p = subprocess.run(
            ["gh", "api", "-X", "POST", f"repos/{repo}/actions/jobs/{row.id}/force-cancel"],
            text=True,
            capture_output=True,
            timeout=_SUBPROCESS_TIMEOUT,
        )
        if p.returncode != 0:
            run_id = raw.get("run_id")
            if run_id:
                _run(["gh", "run", "cancel", str(run_id), "-R", ctx.repo_slug])
                return "workflow run cancel requested (job force-cancel unavailable)"
            raise RuntimeError((p.stderr or p.stdout or "cancel failed").strip())
        return "job cancel requested"
    _run(["gh", "api", "-X", "POST", f"repos/{repo}/actions/jobs/{row.id}/rerun"])
    return "job retry requested"
