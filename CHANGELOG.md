# Changelog

All notable changes to **Antigravity for Claude Code**. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/); versions are in `.claude-plugin/plugin.json`.

## 0.10.0
- **Pricing config** (`prices.json`): single source of current Vertex rates (Opus 4.8
  5/25, Sonnet 4.6 3/15, Gemini 3.5 Flash 1.50/9, Gemini 3.1 Pro 2/12). `measure-session.py`
  now prints an estimated **USD** figure; `agy-cost-compare.sh` defaults come from it
  (env still overrides; Gemini rate picked by tier).
- **doctor**: validates each tier→model name still exists in `agy models` (guards against
  agy renaming models across versions).
- **CHANGELOG.md** added.
- **CI** (GitHub Actions): shellcheck + dependency-free test suite + JSON manifest
  validation on every push/PR.

## 0.9.0
- **Background jobs** (`scripts/agy-job.sh`, codex-style): `start`/`list`/`status`/
  `result`/`cancel`, daemonized worker + per-job registry. Slash commands
  `/antigravity:status|result|cancel`. For interactive sessions; headless stays synchronous.

## 0.8.0
- **Code-review fixes**: mktemp+trap for stderr (was a fixed `/tmp` path = concurrency
  race); friendly arg validation; content-anchored `usage()`; `--yolo` passthrough +
  div-by-zero guard in cost-compare; `with open` + scope caveat + multi-match warning in
  measure-session.
- **Slash commands** `/antigravity:delegate|review|setup`; `scripts/doctor.sh`;
  dependency-free `tests/run-tests.sh`.

## 0.7.x
- Repackaged for public release: sanitized internal identifiers, genericized references,
  MIT `LICENSE`, disclaimer.

## 0.4.0–0.6.0
- Deep-research recipe; verification gates incl. agy tamper-detection; cost-discipline
  section (break-even, lean context, digest, cache-TTL trap); `measure-session.py`;
  `docs/AB-RESULTS.md` (measured A/B) and `docs/DEMO-KIT.md`.

## 0.1.0–0.3.0
- Initial plugin: `agy-delegate.sh` wrapper, `antigravity` skill (SDLC model routing,
  conductor/orchestrator), `agy-cost-compare.sh`, marketplace + plugin manifests.
