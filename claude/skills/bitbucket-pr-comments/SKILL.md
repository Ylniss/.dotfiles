---
name: bitbucket-pr-comments
description: >
  Read the unresolved comment threads of a Bitbucket Cloud pull request,
  general and inline (file:line), labelled C1, C2... Use when the user invokes
  "/bitbucket-pr-comments [pr-url-or-number]" or asks what reviewers wrote on a
  Bitbucket PR.
argument-hint: "[pr-url-or-number]"
---

# Bitbucket PR comments

Read-only: never reply to, resolve or delete a comment.

`bitbucket_pr.py` sits next to this file. Run it with
`py <this skill's directory>/bitbucket_pr.py` on Windows and `python3`
elsewhere. Do not use a bare `python`: on Windows it may resolve to a bundled
interpreter with no CA certificates, and HTTPS then fails with
`CERTIFICATE_VERIFY_FAILED`.

## Steps

1. `bitbucket_pr.py comments [<pr>]`, from the repository's directory.
   `<pr>` is a PR URL (`https://bitbucket.org/<ws>/<repo>/pull-requests/<id>`),
   a bare number (repo taken from `origin`), or nothing (the open PR of the
   current branch).
2. If it exits with `SETUP REQUIRED`, **relay that message to the user and
   stop** — never guess an email or a token, and never write a token into any
   file yourself. After the user sets it up, `bitbucket_pr.py check` verifies it.
3. Show the output to the user as is, keeping the C1, C2... labels so they can
   refer to a thread. Do not summarise away comment text.

A thread counts as resolved when its first comment is resolved; the script
hides those and prints their count. Threads started by integrations (Snyk
etc., author type other than `user`) are hidden the same way. Drafts (pending
comments) are skipped.
