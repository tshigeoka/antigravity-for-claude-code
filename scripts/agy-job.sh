#!/usr/bin/env bash
#
# agy-job.sh — background-job layer over agy-delegate.sh, à la `codex --background`.
# For INTERACTIVE Claude Code sessions: fire a long delegation, keep working, then
# poll :status / fetch :result. (Headless `claude -p` is one-shot — use the wrapper
# synchronously there instead; there is no later turn to collect the result.)
#
# Usage:
#   agy-job.sh start  [agy-delegate options] "task"   # -> prints a JOB_ID, returns now
#   agy-job.sh list                                    # jobs started from this dir
#   agy-job.sh status <id>                             # running | done(rc) | failed
#   agy-job.sh result <id>                             # print stdout (+rc) when finished
#   agy-job.sh cancel <id>                             # terminate a running job
#
# Jobs live under ${ANTIGRAVITY_JOBS:-~/.antigravity-jobs}/<id>/ (out, err, rc, meta).
#
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
DELEGATE="${AGY_DELEGATE:-$HERE/agy-delegate.sh}"
REG="${ANTIGRAVITY_JOBS:-$HOME/.antigravity-jobs}"

die() { echo "agy-job: $*" >&2; exit 1; }

# resolve a (possibly abbreviated) id to a job dir
jobdir() {
  [ -n "${1:-}" ] || die "need a job id"
  if [ -d "$REG/$1" ]; then echo "$REG/$1"; return; fi
  local hits; hits=$(ls -d "$REG/$1"* 2>/dev/null)
  [ -n "$hits" ] || die "no such job: $1"
  [ "$(printf '%s\n' "$hits" | grep -c .)" -eq 1 ] || die "ambiguous id '$1'"
  echo "$hits"
}

# running | done | failed (echoes word; sets RC global for done/failed)
job_state() {
  local jd="$1"
  if [ -f "$jd/rc" ]; then
    RC="$(cat "$jd/rc")"
    [ "$RC" = "0" ] && echo done || echo failed
  elif [ -f "$jd/pid" ] && kill -0 "$(cat "$jd/pid")" 2>/dev/null; then
    echo running
  else
    echo failed   # pid gone, no rc recorded = crashed/killed
  fi
}

cmd="${1:-}"; shift || true
case "$cmd" in
  start)
    [ $# -ge 1 ] || die "start needs delegate args, e.g.  start --tier pro \"task\""
    [ -x "$DELEGATE" ] || die "delegate not executable: $DELEGATE"
    id="$(date +%Y%m%d-%H%M%S)-$$-${RANDOM}"
    jd="$REG/$id"; mkdir -p "$jd"
    { echo "id=$id"; echo "cwd=$PWD"; echo "started=$(date -u +%FT%TZ 2>/dev/null || date)";
      echo "task=$(printf '%s' "${!#}" | tr '\n' ' ' | cut -c1-200)"; } > "$jd/meta"
    ( nohup "$DELEGATE" "$@" >"$jd/out" 2>"$jd/err"; echo $? >"$jd/rc" ) >/dev/null 2>&1 &
    echo $! > "$jd/pid"
    disown 2>/dev/null || true
    echo "$id"
    ;;
  list)
    [ -d "$REG" ] || { echo "(no jobs)"; exit 0; }
    found=0
    for jd in "$REG"/*/; do
      [ -d "$jd" ] || continue
      cwd="$(sed -n 's/^cwd=//p' "$jd/meta" 2>/dev/null)"
      [ "${ALL:-0}" = "1" ] || [ "$cwd" = "$PWD" ] || continue
      found=1
      st="$(job_state "$jd")"
      printf '%-32s %-8s %s\n' "$(basename "$jd")" "$st" \
        "$(sed -n 's/^task=//p' "$jd/meta" 2>/dev/null)"
    done
    [ "$found" = "1" ] || echo "(no jobs for $PWD — set ALL=1 to see all)"
    ;;
  status)
    jd="$(jobdir "${1:-}")"; st="$(job_state "$jd")"
    echo "job:    $(basename "$jd")"
    sed 's/^/  /' "$jd/meta" 2>/dev/null
    echo "  state=$st${RC:+ (rc=$RC)}"
    ;;
  result)
    jd="$(jobdir "${1:-}")"; st="$(job_state "$jd")"
    if [ "$st" = "running" ]; then echo "still running — try again later"; exit 2; fi
    [ -s "$jd/err" ] && { echo "----- stderr -----" >&2; cat "$jd/err" >&2; }
    cat "$jd/out" 2>/dev/null
    echo "[exit rc=${RC:-?}]" >&2
    ;;
  cancel)
    jd="$(jobdir "${1:-}")"
    pid="$(cat "$jd/pid" 2>/dev/null || true)"
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      pkill -P "$pid" 2>/dev/null || true   # children (agy) first
      kill "$pid" 2>/dev/null || true
      echo "cancelled $(basename "$jd")"
    else
      echo "not running"
    fi
    ;;
  ""|-h|--help|help)
    sed -n '/^# Usage:/,/^# Jobs live/p' "$0" | sed 's/^# \{0,1\}//' ;;
  *) die "unknown subcommand '$cmd' (start|list|status|result|cancel)" ;;
esac
