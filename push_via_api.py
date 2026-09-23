#!/usr/bin/env python3
"""Push a local directory to a GitHub repo via the Git API (no git CLI needed).

Creates blobs for every file, one tree, one commit, and points main at it.
Usage: push_via_api.py <project_dir> <owner> <repo>
"""
from __future__ import annotations

import base64
import json
import os
import sys
import urllib.request

sys.path.insert(0, "/opt/hatch/skills/skill-creator/bin")
from dynamic_credentials import (  # noqa: E402
    add_surrogate_to_request,
    read_json_response,
)

CREDENTIAL = "custom.github"
API_BASE = "https://api.github.com"
ALLOWED_HOSTS = ["api.github.com"]

SKIP_DIRS = {".git", "build", ".dart_tool", ".gradle", "outputs"}
SKIP_FILES = {"local.properties", ".DS_Store"}


def api(method: str, path: str, data: dict | None = None):
    url = API_BASE + path
    body = json.dumps(data).encode() if data is not None else None
    req = urllib.request.Request(url, method=method.upper())
    req.add_header("User-Agent", "muse-github-push")
    req.add_header("Accept", "application/vnd.github+json")
    if body:
        req.add_header("Content-Type", "application/json")
    add_surrogate_to_request(req, CREDENTIAL, allowed_hosts=ALLOWED_HOSTS)
    try:
        with urllib.request.urlopen(req, data=body, timeout=60) as resp:
            return resp.status, read_json_response(resp)
    except urllib.error.HTTPError as exc:  # noqa: F821
        raw = exc.read().decode("utf-8", errors="replace")[:2000]
        raise RuntimeError(f"{method} {path} -> {exc.code}: {raw}") from exc


def collect_files(root: str) -> list[tuple[str, str]]:
    out = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS and not d.startswith(".")]
        # keep .github though
        if ".github" not in dirnames and os.path.basename(dirpath) == os.path.basename(root):
            pass
        for fn in filenames:
            if fn in SKIP_FILES or fn.endswith((".apk", ".aab", ".keystore", ".jks")):
                continue
            full = os.path.join(dirpath, fn)
            rel = os.path.relpath(full, root)
            out.append((rel, full))
    return sorted(out)


def main() -> int:
    root, owner, repo = sys.argv[1], sys.argv[2], sys.argv[3]
    base = f"/repos/{owner}/{repo}"

    # re-add .github (skipped by the dotfile filter above)
    files = collect_files(root)
    gh_dir = os.path.join(root, ".github")
    if os.path.isdir(gh_dir):
        for dirpath, _dn, filenames in os.walk(gh_dir):
            for fn in filenames:
                full = os.path.join(dirpath, fn)
                rel = os.path.relpath(full, root)
                files.append((rel, full))
        files = sorted(set(files))

    print(f"pushing {len(files)} files", flush=True)
    tree = []
    for i, (rel, full) in enumerate(files):
        with open(full, "rb") as f:
            content = base64.b64encode(f.read()).decode()
        _s, blob = api("POST", base + "/git/blobs",
                       {"content": content, "encoding": "base64"})
        tree.append({"path": rel, "mode": "100644", "type": "blob",
                     "sha": blob["sha"]})
        if (i + 1) % 50 == 0:
            print(f"  {i + 1}/{len(files)} blobs", flush=True)

    _s, tree_resp = api("POST", base + "/git/trees", {"tree": tree})
    _s, commit = api("POST", base + "/git/commits",
                     {"message": "Current Affairs Flutter app — official Actions build",
                      "tree": tree_resp["sha"]})
    try:
        api("PATCH", base + "/git/refs/heads/main",
            {"sha": commit["sha"], "force": True})
    except RuntimeError as e:
        if "404" in str(e):
            api("POST", base + "/git/refs",
                {"ref": "refs/heads/main", "sha": commit["sha"]})
        else:
            raise
    print("pushed commit", commit["sha"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
