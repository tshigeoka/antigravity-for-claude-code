#!/usr/bin/env bash
# Scripted reproduction of a `/antigravity:delegate` run — for the demo GIF.
# NOTE: this is a representative, deterministic playback (fast + clean), not a live
# capture. It mirrors the real flow: Claude delegates the bulk work to agy (Gemini),
# takes back a digest, and verifies. Preview standalone:  bash docs/demo-playback.sh
set -u
dim=$'\033[2m'; cy=$'\033[36m'; gn=$'\033[32m'; bd=$'\033[1m'; rs=$'\033[0m'

sleep 0.6
printf '%s❯%s %s%s/antigravity:delegate%s --tier flash --dir . "Summarize every README under ./packages — 3 bullets each, with sources."\n\n' "$dim" "$rs" "$bd" "$cy" "$rs"
sleep 1.4
printf '%s⏺%s Delegating the bulk reads to Antigravity (Gemini); keeping my own context lean.\n' "$gn" "$rs"
printf '  %s$ agy-delegate.sh --tier flash --dir .  …%s\n' "$dim" "$rs"
sleep 2.2
printf '%s⏺%s agy returned a digest (12 READMEs → 36 bullets). Spot-checking 3 against the files… %s✓ accurate%s.\n' "$gn" "$rs" "$gn" "$rs"
sleep 1.6
printf '%s⏺%s Done — summary below, plus what I verified.\n' "$gn" "$rs"
sleep 1.2
