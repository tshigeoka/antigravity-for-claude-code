---
description: Delegate a well-scoped subtask to Antigravity (agy/Gemini) under cost discipline, then verify.
argument-hint: "[--tier flash|pro] <task>"
---

Delegate the following task to Antigravity (`agy` / Gemini) via the plugin wrapper,
following the `antigravity` skill's **Cost discipline** and **Verification gates**.

Task: $ARGUMENTS

Do this:
1. Pick a tier (`flash` default; `pro` for hard reasoning). If the task needs the repo,
   add `--dir <repo-root>` so agy reads the real files (don't paste them into context).
   If the task needs tools (web/Vertex AI Search), add `--yolo`.
2. Run **synchronously** (you may be headless — do not background-and-wait):
   `"$CLAUDE_PLUGIN_ROOT/scripts/agy-delegate.sh" --tier <tier> [--dir .] [--yolo] "<task>"`
3. Ingest only the **result/digest** — do NOT re-read the files agy already handled
   (keeps your context lean; that's where the cost savings come from).
4. **Verify**: actually run/check the output; never trust a self-reported "done".
   Report what you delegated and how you verified it.

Remember the break-even: only delegate if the offloaded volume clearly exceeds the
spec + round-trip + verification overhead. Tiny tasks are cheaper to just do yourself.
