# Quickstart: Validating CI and Releases

1. Locally: `python3 -m unittest discover -s tools/tests` and `cd app && swift test` pass;
   `python3 tools/next_version.py` prints 1.0.0.
2. `cd app && MACPLAY_VERSION=1.0.0 ./build.sh && ./make_dmg.sh 1.0.0`: the DMG mounts with MacPlay
   and an Applications link; `shasum -a 256 -c dist/MacPlay-1.0.0.dmg.sha256` passes.
3. Push: the CI workflow's three jobs pass; Security → Code scanning lists a Trivy analysis.
4. Actions → Release → Run workflow with an empty input: the run summary says "Test build", and the
   artifact holds the DMG and its checksum.
5. Run it again with `release`: release v1.0.0 appears with the DMG, checksum and notes.
6. Install from that DMG: MacPlay → About shows 1.0.0.
