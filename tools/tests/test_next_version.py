import os
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import next_version  # noqa: E402


class ClassifyTests(unittest.TestCase):
    def test_types(self):
        self.assertEqual(next_version.classify("feat: add a home screen"), "feature")
        self.assertEqual(next_version.classify("fix(ui): keep the column"), "fix")
        self.assertEqual(next_version.classify("perf: cache artwork"), "fix")
        self.assertEqual(next_version.classify("docs: add a spec"), "other")
        self.assertEqual(next_version.classify("ci(deps): bump actions/checkout"), "other")

    def test_breaking(self):
        self.assertEqual(next_version.classify("feat!: drop macOS 13"), "breaking")
        self.assertEqual(next_version.classify("fix(engine)!: move wrappers"), "breaking")
        self.assertEqual(next_version.classify("refactor: x", "Body.\n\nBREAKING CHANGE: needs 14.6"), "breaking")

    def test_subjects_outside_the_convention_are_ignored(self):
        self.assertIsNone(next_version.classify("README: add a section"))
        self.assertIsNone(next_version.classify("Feat: capitalised type"))


class BumpTests(unittest.TestCase):
    def test_rules(self):
        self.assertEqual(next_version.bump((1, 2, 3), {"fix", "other"}), (1, 2, 4))
        self.assertEqual(next_version.bump((1, 2, 3), {"feature", "fix"}), (1, 3, 0))
        self.assertEqual(next_version.bump((1, 2, 3), {"breaking", "feature"}), (2, 0, 0))
        self.assertIsNone(next_version.bump((1, 2, 3), {"other", None}))

    def test_breaking_change_before_1_0_goes_to_1_0_0(self):
        self.assertEqual(next_version.bump(next_version.parse_version("v0.1.0-alpha"), {"breaking"}), (1, 0, 0))

    def test_parse_version(self):
        self.assertEqual(next_version.parse_version("v0.1.0-alpha"), (0, 1, 0))
        self.assertEqual(next_version.parse_version("v12.0.7"), (12, 0, 7))
        with self.assertRaises(ValueError):
            next_version.parse_version("latest")


class NotesTests(unittest.TestCase):
    def test_grouped_by_kind_without_other_commits(self):
        commits = [
            {"sha": "a" * 40, "subject": "feat(home): add a hero", "body": ""},
            {"sha": "b" * 40, "subject": "fix: keep the column", "body": ""},
            {"sha": "c" * 40, "subject": "docs: add a spec", "body": ""},
            {"sha": "d" * 40, "subject": "feat!: wine 11", "body": ""},
        ]
        notes = next_version.release_notes(commits, "v0.1.0-alpha", "1.0.0", "faldyfin/macplay")
        self.assertIn("## Breaking changes\n\n- wine 11 (ddddddd)", notes)
        self.assertIn("## Features\n\n- **home:** add a hero (aaaaaaa)", notes)
        self.assertIn("## Fixes\n\n- keep the column (bbbbbbb)", notes)
        self.assertNotIn("add a spec", notes)
        self.assertIn("compare/v0.1.0-alpha...v1.0.0", notes)
        self.assertLess(notes.index("Breaking"), notes.index("Features"))


class GitTests(unittest.TestCase):
    """Runs the script against a throwaway repository."""

    def run_git(self, *args):
        subprocess.run(["git", *args], cwd=self.repo, check=True, capture_output=True)

    def commit(self, message):
        self.run_git("commit", "--allow-empty", "-q", "-m", message)

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = self.tmp.name
        self.run_git("init", "-q")
        self.run_git("config", "user.email", "test@example.com")
        self.run_git("config", "user.name", "Test")
        self.commit("feat: first")
        self.run_git("tag", "v1.4.2")

    def tearDown(self):
        self.tmp.cleanup()

    def script(self, *args):
        return subprocess.run([sys.executable, os.path.abspath(next_version.__file__), *args],
                              cwd=self.repo, capture_output=True, text=True)

    def test_only_commits_after_the_tag_count(self):
        self.commit("fix: one")
        self.commit("docs: two")
        notes = os.path.join(self.repo, "notes.md")
        result = self.script("--notes", notes)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "1.4.3")
        with open(notes, encoding="utf-8") as text:
            self.assertIn("- one", text.read())

    def test_footer_breaking_change_is_found_in_the_body(self):
        self.commit("refactor: move\n\nBREAKING CHANGE: new folder")
        self.assertEqual(self.script().stdout.strip(), "2.0.0")

    def test_nothing_to_release(self):
        self.commit("docs: only docs")
        result = self.script()
        self.assertEqual(result.returncode, 1)
        self.assertIn("Nothing to release", result.stderr)


if __name__ == "__main__":
    unittest.main()
