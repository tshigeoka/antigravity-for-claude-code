<div align="center">

# 🛰️ Antigravity for Claude Code

**Run the Antigravity CLI (Gemini) as a collaborating sub-agent, right inside Claude Code.**
Claude conducts the judgement; Gemini does the heavy lifting — intelligent model routing across the SDLC.

[![CI](https://github.com/yuting0624/antigravity-for-claude-code/actions/workflows/ci.yml/badge.svg)](https://github.com/yuting0624/antigravity-for-claude-code/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
![Claude Code plugin](https://img.shields.io/badge/Claude%20Code-plugin-5A4FCF)

</div>

---

## ⚡ Quick look

<!-- Generate the GIF:  brew install vhs && vhs docs/demo.tape   → writes docs/demo.gif, then uncomment: -->
<!-- ![Antigravity for Claude Code demo](docs/demo.gif) -->
> 📹 *Want the GIF? Run `vhs docs/demo.tape` (script included) → `docs/demo.gif`, then uncomment the image above.*

```console
❯ /antigravity:delegate --tier flash --dir . "Summarize every README under ./packages — 3 bullets each, with sources."

⏺ Delegating the bulk reads to Antigravity (Gemini); keeping my own context lean.
  $ agy-delegate.sh --tier flash --dir .  …            # runs agy headless
⏺ agy returned a digest (12 READMEs → 36 bullets). Spot-checking 3 against the files… ✓ accurate.
⏺ Done — here's the summary, and what I verified.
```

Claude stays the conductor; the bulk, token-heavy read ran on cheaper Gemini, and Claude verified the result.

---

## 💡 Why

| | Claude (conductor) | Gemini / `agy` (executor) |
|---|---|---|
| **Owns** | requirements · architecture · the hard 20% · **verification** · review | scaffold · implementation · test generation · search |
| **Strength** | judgement | cheap, fast throughput |

```
you → Claude Code (conduct: design / verify / review)
         └── agy → Gemini (execute: implement / test / search)
```

> *Generation is solved; verification, judgement, and direction are the craft.*

## ✨ What it does

- **Routes work across the SDLC** — Claude keeps the judgement calls; Antigravity handles scaffolding, **test generation**, **first-pass review**, and **migrations** under a shared `AGENTS.md`.
- **Adds tools Claude lacks natively** — live **Google/web search**, **Vertex AI Search** over your internal data, deep research, Cloud Logging. Claude reviews and re-checks the results.
- **Cross-model verification** — an independent, different-model opinion on your code.
- **Background jobs** — fire a long delegation, keep working, collect later.
- **Built-in cost discipline** — measured, not guessed (see below).

## 📊 Measured results

On a **large** ADK multi-agent build (+ `adk eval`), same task / same model, 3 ways:

| | Claude solo @high | solo @max | **hybrid** |
|---|---|---|---|
| frontier cost (COST-WEIGHTED) | 2.62M | 5.34M | **1.91M** |
| quality (`adk eval`) | ✅ 3/3 | ✅ 3/3 | ✅ **3/3** |

→ **−27% vs solo@high, −64% vs solo@max, at equal quality** — and the cheap Gemini work isn't even counted. Savings scale with task size; tiny one-off tasks are cheaper to just run on Claude. Full A/B: [`docs/AB-RESULTS.md`](docs/AB-RESULTS.md).

> **Note on cost figures:** numbers are **estimates** — token counts are approximated and rates live in [`prices.json`](prices.json). **Set your real Vertex rates there before quoting any figure.**

## 🚀 Install

In Claude Code:
```
/plugin marketplace add yuting0624/antigravity-for-claude-code
/plugin install antigravity@antigravity-for-claude-code
/antigravity:setup        # verifies agy is installed + authenticated
```

**Prerequisites:** the [Antigravity CLI](https://antigravity.google/docs/cli-using) (`agy`) installed & authenticated (`agy models` lists Gemini models), and Claude Code. For the same-bill cost benefit, run Claude Code on Vertex too.

## 🧩 Slash commands

| command | what it does |
|---|---|
| `/antigravity:setup` | health check — `agy` installed + authenticated, scripts ready |
| `/antigravity:delegate [--tier flash\|pro] <task>` | delegate a subtask to agy under cost discipline, then verify |
| `/antigravity:review [--adversarial]` | independent cross-model review of the current diff; Claude reconciles |
| `/antigravity:status [id]` · `:result <id>` · `:cancel <id>` | manage background delegation jobs |

> Background jobs are for **interactive** sessions (fire-and-collect). In headless `claude -p` (one-shot), delegate **synchronously** — there's no later turn to collect a result.

---

<details>
<summary><b>🛠️ Direct script usage &amp; tiers</b></summary>

```bash
# one-shot delegation (plain text on stdout)
scripts/agy-delegate.sh --tier flash "Summarize this changelog in 3 bullets: ..."

# give Antigravity a workspace for multi-file agentic work
scripts/agy-delegate.sh --tier pro --dir ./src "List every TODO with file:line"

# live web / Google search (tools need --yolo in headless mode)
scripts/agy-delegate.sh --tier pro --yolo "Web-search <X>. Give URLs + dates."

# Vertex AI Search over internal data
scripts/agy-delegate.sh --tier pro --yolo "List Vertex AI Search engines (list_engines)."

# cross-model review / stdin / background job
scripts/agy-delegate.sh --tier pro "Review for bugs, be skeptical: <paste>"
cat big-prompt.txt | scripts/agy-delegate.sh -
ID=$(scripts/agy-job.sh start --tier pro --dir . "big task"); scripts/agy-job.sh result "$ID"
```

| tier | model | use for |
|------|-------|---------|
| `flash` (default) | Gemini 3.5 Flash (High) | most bulk work |
| `flash-lo` | Gemini 3.5 Flash (Low) | cheapest, trivial tasks |
| `pro` | Gemini 3.1 Pro (High) | harder reasoning / cross-checks |

</details>

<details>
<summary><b>💸 How to actually get the savings (cost discipline)</b></summary>

Delegation doesn't save money by itself — these do (also in the skill):

1. **Delegate above the break-even** — bulk/parallel/repetitive work, not tiny tasks.
2. **Keep Claude's context lean** — don't re-read what agy already handled; take a **digest**, not raw output. (Biggest lever — it collapses `cache_read`.)
3. **Batch** — one big delegation beats many round-trips.
4. **Review the diff, not the whole tree.**

`scripts/measure-session.py <session-id>` prints the COST-WEIGHTED + est. USD breakdown for a session (Claude side; Gemini side priced separately). `scripts/agy-cost-compare.sh` shows the per-token gap for a task — **estimates from char-count, so verify `prices.json` first.**

</details>

<details>
<summary><b>🚧 Guardrails &amp; known limits</b></summary>

**Guardrails**
- Always **verify** agy's output (it can be wrong, and may even alter its environment to make a check pass — re-run gates yourself in a clean state).
- `--yolo` auto-approves every tool call — use with `--sandbox` or in a throwaway dir.
- Write tasks: run on a dedicated branch/worktree, review the diff before merging.

**Known limits (agy v1.0.x)**
- `-p`/`--print` **takes the prompt as its value** and must come last — the wrapper handles this.
- No `--output-format json` (plain text); `--print` drops stdout on a non-TTY unless stdin is detached (handled via `< /dev/null`).

</details>

<details>
<summary><b>📦 What's inside · local dev · tests</b></summary>

```
.claude-plugin/   plugin + marketplace manifests
skills/antigravity/SKILL.md   WHEN + HOW Claude collaborates with agy
commands/         slash commands (delegate, review, setup, status, result, cancel)
scripts/          agy-delegate · agy-job · agy-cost-compare · measure-session · doctor
docs/             AB-RESULTS (measured A/B) · DEMO-KIT
prices.json       Vertex rate config (verify before quoting)
```

**Local development** (hack on the plugin — loads live files, `$CLAUDE_PLUGIN_ROOT` resolves):
```bash
git clone https://github.com/yuting0624/antigravity-for-claude-code ~/antigravity-for-claude-code
claude --plugin-dir ~/antigravity-for-claude-code
```

**Tests** (no dependencies; stubs `agy`):
```bash
bash tests/run-tests.sh
```

</details>

---

## ⚠️ Disclaimer

Community project. **Not affiliated with, endorsed by, or supported by Google or Anthropic.** "Antigravity", "Gemini", "Claude", and "Claude Code" are trademarks of their respective owners. This plugin orchestrates the third-party `agy` CLI; you are responsible for your own API/cloud costs, credentials, and data-sharing choices. MIT licensed — see [LICENSE](LICENSE).
