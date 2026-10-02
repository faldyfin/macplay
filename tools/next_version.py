#!/usr/bin/env python3
"""Next release version and release notes from the Conventional Commits since the last tag.

A breaking change (`type!:` or a `BREAKING CHANGE:` footer) bumps the major version, `feat`
the minor, `fix`, `perf` and `revert` the patch. Other types (docs, ci, chore, refactor...)
release nothing, and neither do subjects that don't follow the convention.

Prints the version (no leading "v") and writes the notes to --notes. Exits with 1 when
there is nothing to release. Standard library only.
"""
import argparse
import os
import re
import subprocess
import sys

HEADER = re.compile(r"^(?P<type>[a-z]+)(?:\((?P<scope>[^)]*)\))?(?P<bang>!)?: (?P<description>.+)$")
BREAKING_FOOTER = re.compile(r"^BREAKING[ -]CHANGE: ", re.MULTILINE)
VERSION = re.compile(r"^v?(\d+)\.(\d+)\.(\d+)(?:-[0-9A-Za-z.-]+)?$")
PATCH_TYPES = {"fix", "perf", "revert"}
SECTIONS = [("breaking", "Breaking changes"), ("feature", "Features"), ("fix", "Fixes")]


def parse_version(tag):
    """(major, minor, patch) of a tag like v1.2.3 or v0.1.0-alpha; the pre-release part is dropped."""
    match = VERSION.match(tag)
    if not match:
        raise ValueError(f"not a version tag: {tag}")
    return tuple(int(part) for part in match.groups())


def classify(subject, body=""):
    """'breaking', 'feature', 'fix', 'other', or None for a subject outside the convention."""
    match = HEADER.match(subject)
    if not match:
        return None
    if match["bang"] or BREAKING_FOOTER.search(body):
        return "breaking"
    if match["type"] == "feat":
        return "feature"
    if match["type"] in PATCH_TYPES:
        return "fix"
    return "other"


def bump(base, kinds):
    """The version after `base` for commits of these kinds, or None when none of them releases."""
    major, minor, patch = base
    if "breaking" in kinds:
        return (major + 1, 0, 0)
    if "feature" in kinds:
        return (major, minor + 1, 0)
    if "fix" in kinds:
        return (major, minor, patch + 1)
    return None


def release_notes(commits, previous_tag=None, version=None, repository=None):
    """Markdown grouped by kind; commits are dicts with sha, subject and body."""
    lines = []
    for kind, heading in SECTIONS:
        entries = []
        for commit in commits:
            if classify(commit["subject"], commit["body"]) != kind:
                continue
            match = HEADER.match(commit["subject"])
            scope = f"**{match['scope']}:** " if match["scope"] else ""
            entries.append(f"- {scope}{match['description']} ({commit['sha'][:7]})")
        if entries:
            lines += [f"## {heading}", "", *entries, ""]
    if previous_tag and version and repository:
        lines.append(f"**Full changelog**: https://github.com/{repository}/compare/{previous_tag}...v{version}")
    return "\n".join(lines).strip() + "\n"


def git(*args):
    return subprocess.run(["git", *args], check=True, capture_output=True, text=True).stdout


def last_tag():
    try:
        return git("describe", "--tags", "--abbrev=0", "--match", "v[0-9]*").strip()
    except subprocess.CalledProcessError:
        return None


def commits_since(tag):
    revision = f"{tag}..HEAD" if tag else "HEAD"
    log = git("log", "--no-merges", "--format=%H%x1f%s%x1f%b%x1e", revision)
    commits = []
    for record in log.split("\x1e"):
        if record.strip():
            sha, subject, body = record.strip("\n").split("\x1f")
            commits.append({"sha": sha, "subject": subject, "body": body})
    return commits


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--notes", help="write the release notes to this file")
    args = parser.parse_args()

    tag = last_tag()
    base = parse_version(tag) if tag else (0, 0, 0)
    commits = commits_since(tag)
    version = bump(base, {classify(c["subject"], c["body"]) for c in commits})
    if version is None:
        print(f"Nothing to release since {tag or 'the first commit'}: no feat, fix or breaking commits.",
              file=sys.stderr)
        return 1

    text = ".".join(str(part) for part in version)
    if args.notes:
        with open(args.notes, "w", encoding="utf-8") as notes:
            notes.write(release_notes(commits, tag, text, os.environ.get("GITHUB_REPOSITORY")))
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
