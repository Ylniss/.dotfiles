#!/usr/bin/env python3
"""Print the unresolved comment threads of a Bitbucket Cloud pull request.

Credentials come from ~/.claude/.bitbucket.env (or the same environment
variables), in the form KEY=value:

    BITBUCKET_EMAIL=you@example.com
    BITBUCKET_TOKEN=...

Usage:
    comments [<pr-url-or-number>]   no argument: the open PR of the current branch
    check                           verify the credentials
    setup                           print the credentials setup message
"""
import argparse
import base64
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

API = "https://api.bitbucket.org/2.0"
ENV_FILE = Path.home() / ".claude" / ".bitbucket.env"
REQUIRED_KEYS = ("BITBUCKET_EMAIL", "BITBUCKET_TOKEN")


def die(message):
    sys.stderr.write("error: %s\n" % message)
    raise SystemExit(1)


def setup_hint(missing):
    if os.name == "nt":
        command = "\n    ".join([
            "PowerShell: Set-Content $env:USERPROFILE\\.claude\\.bitbucket.env @("
            "'BITBUCKET_EMAIL=<your atlassian email>',"
            "'BITBUCKET_TOKEN=<token>')",
            "nushell:    \"BITBUCKET_EMAIL=<your atlassian email>\\nBITBUCKET_TOKEN=<token>\\n\""
            " | save -f ~/.claude/.bitbucket.env",
        ])
    else:
        command = (
            "mkdir -p ~/.claude && printf '%s\\n' "
            "'BITBUCKET_EMAIL=<your atlassian email>' "
            "'BITBUCKET_TOKEN=<token>' > ~/.claude/.bitbucket.env "
            "&& chmod 600 ~/.claude/.bitbucket.env"
        )
    return "\n".join([
        "SETUP REQUIRED: %s missing from %s" % (", ".join(missing), ENV_FILE),
        "",
        "Ask the user to paste this command, with the placeholders filled in:",
        "",
        "    " + command,
        "",
        "Token: https://id.atlassian.com/manage-profile/security/api-tokens",
        "  Create API token with scopes -> app Bitbucket -> scopes",
        "  read:pullrequest:bitbucket and read:repository:bitbucket.",
        "Email: the address of the Atlassian account that owns the token.",
    ])


def load_config():
    cfg = {}
    if ENV_FILE.exists():
        for line in ENV_FILE.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            cfg[key.strip()] = value.strip().strip('"').strip("'")
    for key in REQUIRED_KEYS:
        if os.environ.get(key):
            cfg[key] = os.environ[key]
    missing = [key for key in REQUIRED_KEYS if not cfg.get(key)]
    if missing:
        die(setup_hint(missing))
    return cfg


def request(cfg, url):
    credentials = "%s:%s" % (cfg["BITBUCKET_EMAIL"], cfg["BITBUCKET_TOKEN"])
    req = urllib.request.Request(url)
    req.add_header("Authorization", "Basic " + base64.b64encode(credentials.encode()).decode())
    req.add_header("Accept", "application/json")
    try:
        with urllib.request.urlopen(req) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        detail = error.read().decode("utf-8", "replace")[:2000]
        die("GET %s -> HTTP %s\n%s" % (url, error.code, detail))
    except urllib.error.URLError as error:
        hint = ""
        if "CERTIFICATE_VERIFY_FAILED" in str(error.reason):
            hint = ("\nThis interpreter has no CA bundle (a bundled Python, e.g. Inkscape's)."
                    "\nRun the script with the system Python: `py` on Windows, `python3` elsewhere.")
        die("GET %s -> %s%s" % (url, error.reason, hint))


def paged(cfg, url):
    while url:
        page = request(cfg, url)
        yield from page["values"]
        url = page.get("next")


def git(*args):
    result = subprocess.run(["git", *args], capture_output=True, text=True)
    if result.returncode != 0:
        die("git %s failed: %s" % (" ".join(args), result.stderr.strip()))
    return result.stdout.strip()


def origin_repo():
    url = git("remote", "get-url", "origin")
    match = re.search(r"bitbucket\.org[:/]([^/]+)/([^/]+?)(?:\.git)?/?$", url)
    if not match:
        die("origin %r is not a bitbucket.org repository" % url)
    return match.group(1), match.group(2)


def resolve_pr(cfg, reference):
    if reference:
        match = re.search(r"bitbucket\.org/([^/]+)/([^/]+)/pull-requests/(\d+)", reference)
        if match:
            return match.group(1), match.group(2), match.group(3)
        if not reference.isdigit():
            die("cannot read a pull request out of %r" % reference)
        return (*origin_repo(), reference)

    workspace, repo = origin_repo()
    branch = git("branch", "--show-current")
    query = urllib.parse.quote('source.branch.name="%s" AND state="OPEN"' % branch)
    url = "%s/repositories/%s/%s/pullrequests?q=%s" % (API, workspace, repo, query)
    prs = list(paged(cfg, url))
    if not prs:
        die("no open pull request from branch %r in %s/%s" % (branch, workspace, repo))
    if len(prs) > 1:
        die("several open pull requests from %r: %s; pass one"
            % (branch, ", ".join("#%s" % pr["id"] for pr in prs)))
    return workspace, repo, str(prs[0]["id"])


def thread_root(comment, by_id):
    while comment.get("parent"):
        comment = by_id[comment["parent"]["id"]]
    return comment


def location(root):
    inline = root.get("inline")
    if not inline:
        return ""
    if inline.get("to"):
        return "%s:%s" % (inline["path"], inline["to"])
    if inline.get("from"):
        return "%s:%s (old side)" % (inline["path"], inline["from"])
    return inline["path"]


def byline(comment):
    return "%s (%s)" % (comment["user"]["display_name"], comment["created_on"][:10])


def cleaned(text):
    """Undo the markdown escapes and zero-width characters Bitbucket's editor stores."""
    text = re.sub(r"\\([\\`*_{}\[\]()#+\-.!|<>~])", r"\1", text)
    return re.sub("[\u200b-\u200d\ufeff]", "", text).strip()


def indented(text, prefix):
    return "\n".join(prefix + line for line in cleaned(text).splitlines() or [""])


def cmd_comments(args):
    cfg = load_config()
    workspace, repo, pr_id = resolve_pr(cfg, args.pr)
    pr_endpoint = "%s/repositories/%s/%s/pullrequests/%s" % (API, workspace, repo, pr_id)
    pr = request(cfg, pr_endpoint)
    # Drafts (pending) are visible only to the token owner and not yet posted.
    comments = [c for c in paged(cfg, pr_endpoint + "/comments?pagelen=100") if not c.get("pending")]

    by_id = {c["id"]: c for c in comments}
    threads = {}
    for comment in sorted(comments, key=lambda c: c["created_on"]):
        threads.setdefault(thread_root(comment, by_id)["id"], []).append(comment)

    resolved = bots = 0
    general_threads, inline_threads = [], []
    for root_id, thread in threads.items():
        root = by_id[root_id]
        if root.get("resolution"):
            resolved += 1
            continue
        # Integrations (Snyk etc.) post as the workspace ("team") or an "app_user", people as "user".
        if root["user"]["type"] != "user":
            bots += 1
            continue
        visible = [c for c in thread if not c["deleted"]]
        if not visible:
            continue
        (inline_threads if root.get("inline") else general_threads).append((root, visible))
    inline_threads.sort(key=lambda t: (t[0]["inline"]["path"],
                               t[0]["inline"].get("to") or t[0]["inline"].get("from") or 0))

    print("PR #%s: %s" % (pr["id"], pr["title"]))
    print("%s · %s -> %s · %s" % (pr["author"]["display_name"], pr["source"]["branch"]["name"],
                                  pr["destination"]["branch"]["name"], pr["state"]))
    print(pr["links"]["html"]["href"])

    label = 0
    for heading, group in (("General", general_threads), ("Inline", inline_threads)):
        if not group:
            continue
        print("\n## %s" % heading)
        for root, visible in group:
            label += 1
            where = location(root)
            print("\nC%d  %s%s" % (label, where + " — " if where else "", byline(visible[0])))
            if root["deleted"]:
                print("    [first comment deleted]")
            print(indented(visible[0]["content"]["raw"], "    "))
            for reply in visible[1:]:
                print("    ↳ %s:" % byline(reply))
                print(indented(reply["content"]["raw"], "      "))

    if not label:
        print("\nNo unresolved comments.")
    if resolved:
        print("\n%d resolved thread(s) hidden." % resolved)
    if bots:
        print("\n%d bot thread(s) hidden." % bots)


def cmd_check(args):
    cfg = load_config()
    workspace, repo = origin_repo()
    # /user would need an extra account scope; the repository needs only the ones the setup asks for.
    request(cfg, "%s/repositories/%s/%s" % (API, workspace, repo))
    print("ok: %s/%s readable" % (workspace, repo))


def cmd_setup(args):
    print(setup_hint(REQUIRED_KEYS))


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)

    comments = sub.add_parser("comments")
    comments.add_argument("pr", nargs="?", help="PR URL or number; omitted: current branch")
    comments.set_defaults(func=cmd_comments)

    sub.add_parser("check").set_defaults(func=cmd_check)
    sub.add_parser("setup").set_defaults(func=cmd_setup)

    args = parser.parse_args()
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    args.func(args)


if __name__ == "__main__":
    main()
