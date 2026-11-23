#!/usr/bin/env bash
# Agent-kit installer for macOS and Linux. Same behavior as install.ps1 (Windows).
#
# Wires Agent-kit rules and skills into Claude Code, Antigravity (Gemini) and Codex.
# Idempotent: running it twice gives the same result.
# Rule sources: rules/GLOBAL.md (shared) plus local/MODELS.md and local/PREFS.md (personal,
# git-ignored, written by the setup skill). If a local file is missing, it stops before changing anything.
#   Claude:      adds @imports of the three rule files to ~/.claude/CLAUDE.md
#                (a copy of the rules instead, if the kit path has a space)
#   Antigravity: copies the rules into ~/.gemini/GEMINI.md
#   Codex:       copies the rules into ~/.codex/AGENTS.md
# Each harness gets a marked block (agent-kit:start / agent-kit:end) that is updated in place;
# text outside it is never touched.
# Claude and Codex skills are symlinks, so kit edits are live. Antigravity gets copies (each with a
# .agent-kit-copy marker file). Links or copies of skills removed from the kit are pruned.
# Copied rules and Antigravity skills need a re-run after you edit the kit.
# Any file or copied skill it changes or removes is backed up first to ~/.agent-kit-backups/<timestamp>/.
#
# Runs on bash 3.2 (the macOS default) and later, with POSIX tools only
# (awk, cksum, cmp, cp, find, ln, mktemp, readlink, tail).

usage() {
  cat <<'EOF'
Usage: bash install/install.sh [--dry-run] [--harness LIST] [--uninstall]

  --dry-run        Show what would change. Change nothing.
  --harness LIST   Limit to some harnesses: claude, gemini, codex, comma-separated
                   (for example --harness claude,gemini). Default: all three.
  --uninstall      Remove the marked blocks and the skill links and copies this script created.
  -h, --help       Show this help.
EOF
}

DRY_RUN=0
UNINSTALL=0
HARNESS_ARG=
HARNESS_SET=0
while [ $# -gt 0 ]; do
  case $1 in
    --dry-run) DRY_RUN=1 ;;
    --uninstall) UNINSTALL=1 ;;
    --harness)
      if [ $# -lt 2 ]; then
        echo "--harness needs a value: claude, gemini or codex, comma-separated."
        exit 1
      fi
      HARNESS_ARG="$HARNESS_ARG,$2"; HARNESS_SET=1; shift ;;
    --harness=*) HARNESS_ARG="$HARNESS_ARG,${1#--harness=}"; HARNESS_SET=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
  shift
done

# Split the harness list on commas and spaces, lower-case it, drop duplicates, check each name.
[ "$HARNESS_SET" = 1 ] || HARNESS_ARG=claude,gemini,codex
HARNESS=
BAD=
SEEN=' '
set -f
for h in $(printf '%s' "$HARNESS_ARG" | tr ',' ' ' | tr '[:upper:]' '[:lower:]'); do
  case $SEEN in *" $h "*) continue ;; esac
  SEEN="$SEEN$h "
  case $h in
    claude|gemini|codex) HARNESS="$HARNESS $h" ;;
    *) BAD="$BAD${BAD:+, }$h" ;;
  esac
done
set +f
if [ -z "$HARNESS" ] || [ -n "$BAD" ]; then
  echo "Unknown --harness value: $BAD. Use claude, gemini or codex, comma-separated."
  exit 1
fi

KIT=$(cd "$(dirname "$0")/.." && pwd -P) || exit 1
KIT_SKILLS="$KIT/skills"
if [ -z "$HOME" ]; then
  echo "HOME is not set."
  exit 1
fi
HOME_DIR=${HOME%/}
HOME_PHYS=$(cd "$HOME" 2>/dev/null && pwd -P) || HOME_PHYS=$HOME_DIR
STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$HOME_DIR/.agent-kit-backups/$STAMP"
n=1
while [ -e "$BACKUP_DIR" ]; do
  n=$((n + 1))
  BACKUP_DIR="$HOME_DIR/.agent-kit-backups/$STAMP-$n"
done
START='<!-- agent-kit:start (managed by Agent-kit install.sh; edits inside are overwritten) -->'
END='<!-- agent-kit:end -->'
COPY_MARKER=.agent-kit-copy
RULE_FILES='rules/GLOBAL.md local/MODELS.md local/PREFS.md'
CHANGES=0

if [ "$UNINSTALL" = 0 ]; then
  MISSING=
  for f in $RULE_FILES; do
    [ -e "$KIT/$f" ] || MISSING="$MISSING${MISSING:+, }$f"
  done
  if [ -n "$MISSING" ]; then
    echo "Agent-kit: $KIT"
    echo "Missing: $MISSING. Nothing was changed."
    echo 'Run setup first: tell your agent "set up Agent-kit" (it follows INSTALL.md),'
    echo 'or copy rules/MODELS.example.md to local/MODELS.md and write local/PREFS.md by hand.'
    exit 1
  fi
fi

WORK=$(mktemp -d "${TMPDIR:-/tmp}/agent-kit.XXXXXX") || { echo "Cannot create a temp folder."; exit 1; }
trap 'rm -rf "$WORK"' EXIT

say() { printf '%s\n' "$*"; }
step() { if [ "$DRY_RUN" = 1 ]; then say "[dry-run] $*"; else say "$*"; fi; }
warn() { say "WARNING: $*" >&2; }
die() { say "ERROR: $*" >&2; exit 1; }

backup_item() {
  # Copies a file or folder to the backup dir, keeping its path relative to the home folder.
  local p=$1 rel dest
  [ -e "$p" ] || return 0
  case $p in
    "$HOME_DIR"/*) rel=${p#"$HOME_DIR"/} ;;
    *) rel=${p#/} ;;
  esac
  dest="$BACKUP_DIR/$rel"
  if [ "$DRY_RUN" = 1 ]; then step "backup  $p"; return 0; fi
  mkdir -p "$(dirname "$dest")" || die "cannot create $(dirname "$dest")"
  cp -R "$p" "$dest" || die "cannot back up $p"
}

# Prints the new text of a file with a managed block. Exit 3 = broken or duplicate markers.
# Reads the current file. Environment: AK_HASNL (1 if the file ends with a newline), AK_BODY (file
# with the block body; empty body = remove the block), AK_START, AK_END.
# Same rules as Set-ManagedBlock in install.ps1: CRLF files stay CRLF, text outside the block is kept.
BLOCK_AWK='
function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s }
function trim(s) { sub(/^[ \t\r\n]+/, "", s); return rtrim(s) }
{ cr[NR] = sub(/\r$/, ""); L[NR] = $0 }
END {
  n = NR; hasnl = ENVIRON["AK_HASNL"] + 0
  if (n > 0 && cr[n] && !hasnl) L[n] = L[n] "\r"
  crlf = 0
  for (i = 1; i <= n; i++) if (cr[i] && (i < n || hasnl)) crlf = 1
  starts = 0; ends = 0; s = 0; e = 0
  for (i = 1; i <= n; i++) {
    if (L[i] ~ /^<!-- agent-kit:start([^A-Za-z0-9_].*)?-->[ \t]*$/) { starts++; if (!s) s = i }
    else if (L[i] ~ /^<!-- agent-kit:end -->[ \t]*$/) { ends++; if (s && !e) e = i }
  }
  if (starts > 1 || starts != ends || (starts == 1 && !e)) exit 3
  text = ""
  for (i = 1; i <= n; i++) text = text (i > 1 ? "\n" : "") L[i]
  if (hasnl) text = text "\n"
  body = ""; nb = 0; bodyfile = ENVIRON["AK_BODY"]
  while ((getline line < bodyfile) > 0) { sub(/\r$/, "", line); body = (nb++ ? body "\n" : "") line }
  body = trim(body)
  prefix = ""; suffix = ""
  if (e) {
    for (i = 1; i < s; i++) prefix = prefix L[i] "\n"
    for (i = e + 1; i <= n; i++) suffix = suffix "\n" L[i]
    if (hasnl) suffix = suffix "\n"
  }
  if (body != "") {
    block = ENVIRON["AK_START"] "\n" body "\n" ENVIRON["AK_END"]
    if (e) out = prefix block suffix
    else { o = rtrim(text); out = (o != "") ? o "\n\n" block "\n" : block "\n" }
  } else if (e) {
    b = rtrim(prefix); a = suffix; sub(/^\n+/, "", a)
    out = (b != "" && a != "") ? b "\n\n" a : (b != "" ? b "\n" : a)
  } else out = text
  if (crlf) gsub(/\n/, "\r\n", out)
  printf "%s", out
}'

# Prints a file with CRLF turned into LF, a leading UTF-8 BOM dropped and outer whitespace trimmed.
TRIM_AWK='
{ sub(/\r$/, ""); if (NR == 1) sub(/^\357\273\277/, ""); t = (NR > 1 ? t "\n" : "") $0 }
END { sub(/^[ \t\r\n]+/, "", t); sub(/[ \t\r\n]+$/, "", t); printf "%s", t }'

set_managed_block() {
  local path=$1 body=$2 src=/dev/null hasnl=0 new="$WORK/new" rc
  if [ -e "$path" ]; then
    src=$path
    if [ -s "$path" ] && [ -z "$(tail -c 1 "$path")" ]; then hasnl=1; fi
  fi
  # BINMODE=3: gawk builds for Windows (Git Bash) drop \r on input unless told to use binary mode.
  # Other awks ignore the variable.
  AK_HASNL=$hasnl AK_BODY=$body AK_START=$START AK_END=$END LC_ALL=C awk -v BINMODE=3 "$BLOCK_AWK" "$src" > "$new"
  rc=$?
  if [ $rc -eq 3 ]; then
    warn "skip    $path has broken or duplicate agent-kit markers. Fix them by hand, then re-run."
    return 0
  fi
  [ $rc -eq 0 ] || die "cannot read $path"
  if cmp -s "$new" "$src"; then say "ok      $path (no change)"; return 0; fi
  backup_item "$path"
  CHANGES=$((CHANGES + 1))
  if ! grep -q '[^[:space:]]' "$new"; then
    step "delete  $path (nothing left in it)"
    if [ "$DRY_RUN" = 0 ]; then rm -f -- "$path" || die "cannot delete $path"; fi
    return 0
  fi
  step "write   $path"
  [ "$DRY_RUN" = 1 ] && return 0
  mkdir -p "$(dirname "$path")" || die "cannot create $(dirname "$path")"
  cat "$new" > "$path" || die "cannot write $path"
}

make_rules_text() {
  # Writes the three rule files, joined, to $1.
  local out=$1 f first=1
  {
    printf '<!-- Copied from %s (rules/GLOBAL.md, local/MODELS.md, local/PREFS.md). Edit there, then re-run install.sh. -->\n\n' "$KIT"
    for f in $RULE_FILES; do
      [ $first = 1 ] || printf '\n\n'
      first=0
      LC_ALL=C awk -v BINMODE=3 "$TRIM_AWK" "$KIT/$f"
    done
  } > "$out" || die "cannot write $out"
}

claude_body() {
  # Writes the Claude block body to $1: @imports, or a copy of the rules if the path has a space.
  local out=$1 k=$KIT f
  case $KIT in
    "$HOME_PHYS"/*) k="~${KIT#"$HOME_PHYS"}" ;;
    "$HOME_DIR"/*) k="~${KIT#"$HOME_DIR"}" ;;
  esac
  case $k in
    *' '*)
      # @imports stop at a space, so copy the rules instead.
      warn "The kit path has a space, so Claude gets a copy of the rules. Re-run install.sh after editing them."
      make_rules_text "$out" ;;
    *)
      for f in $RULE_FILES; do printf '@%s/%s\n' "$k" "$f"; done > "$out" || die "cannot write $out" ;;
  esac
}

SKILLS=()
for d in "$KIT_SKILLS"/*/; do
  d=${d%/}
  [ -f "$d/SKILL.md" ] || continue
  SKILLS+=("$(basename "$d")")
done

in_skills() {
  local s
  for s in "${SKILLS[@]}"; do [ "$s" = "$1" ] && return 0; done
  return 1
}

link_target() {
  # Prints the target of a symlink, or nothing if $1 is not a symlink.
  if [ -L "$1" ]; then readlink "$1"; fi
}

is_ours() {
  # True if the symlink $1 points to <kit>/skills/$2 (the folder may no longer exist).
  local target
  target=$(link_target "$1")
  [ -n "$target" ] || return 1
  [ "${target%/}" = "$KIT_SKILLS/$2" ] && return 0
  [ -e "$1" ] && [ "$(cd "$1" 2>/dev/null && pwd -P)" = "$KIT_SKILLS/$2" ]
}

remove_stale_skills() {
  # Links or copies made by this script for skills that are no longer in the kit.
  local dir=$1 item name
  [ -d "$dir" ] || return 0
  for item in "$dir"/* "$dir"/.[!.]* "$dir"/..?*; do
    [ -e "$item" ] || [ -L "$item" ] || continue
    name=$(basename "$item")
    in_skills "$name" && continue
    if [ -L "$item" ]; then
      if is_ours "$item" "$name"; then
        CHANGES=$((CHANGES + 1))
        step "unlink  $item (skill no longer in the kit)"
        if [ "$DRY_RUN" = 0 ]; then rm -f -- "$item" || die "cannot remove $item"; fi
      fi
    elif [ -d "$item" ] && [ -e "$item/$COPY_MARKER" ]; then
      backup_item "$item"
      CHANGES=$((CHANGES + 1))
      step "remove  $item (skill no longer in the kit)"
      if [ "$DRY_RUN" = 0 ]; then rm -rf -- "$item" || die "cannot remove $item"; fi
    fi
  done
}

set_skill_links() {
  local dir=$1 name link src target ours dangling verb
  for name in "${SKILLS[@]}"; do
    link="$dir/$name"
    src="$KIT_SKILLS/$name"
    target=$(link_target "$link")
    ours=0; is_ours "$link" "$name" && ours=1
    dangling=0; if [ -n "$target" ] && [ ! -e "$link" ]; then dangling=1; fi
    if [ "$UNINSTALL" = 1 ]; then
      if [ $ours = 1 ]; then
        CHANGES=$((CHANGES + 1))
        step "unlink  $link"
        if [ "$DRY_RUN" = 0 ]; then rm -f -- "$link" || die "cannot remove $link"; fi
      fi
      continue
    fi
    if [ $ours = 1 ] && [ $dangling = 0 ]; then say "ok      $link (linked)"; continue; fi
    if [ -n "$target" ] && [ $ours = 0 ] && [ $dangling = 0 ]; then
      warn "skip    $link is a link to $target, not to this kit. Move it, then re-run."
      continue
    fi
    if [ -z "$target" ] && [ -e "$link" ]; then
      warn "skip    $link exists and is not an Agent-kit link. Move it, then re-run."
      continue
    fi
    CHANGES=$((CHANGES + 1))
    if [ -n "$target" ]; then verb=relink; else verb='link  '; fi
    step "$verb  $link -> $src"
    [ "$DRY_RUN" = 1 ] && continue
    if [ -n "$target" ]; then rm -f -- "$link" || die "cannot remove $link"; fi  # broken link, e.g. the kit was moved
    mkdir -p "$dir" || die "cannot create $dir"
    ln -s "$src" "$link" || die "cannot link $link"
  done
  remove_stale_skills "$dir"
}

dir_signature() {
  # Relative path, CRC and size of every file, skipping our marker. Same signature = same content.
  (cd "$1" && find . -type f ! -name "$COPY_MARKER" -exec cksum {} +) | LC_ALL=C sort
}

set_skill_copies() {
  # Antigravity gets real copies, as on Windows. Each copy holds a marker file so the script
  # knows it owns the folder.
  local dir=$1 name dest src target old_link is_copy verb
  for name in "${SKILLS[@]}"; do
    dest="$dir/$name"
    src="$KIT_SKILLS/$name"
    target=$(link_target "$dest")
    old_link=0
    if [ -n "$target" ]; then
      if is_ours "$dest" "$name" || [ ! -e "$dest" ]; then old_link=1; fi
    fi
    is_copy=0
    if [ -z "$target" ] && [ -e "$dest/$COPY_MARKER" ]; then is_copy=1; fi
    if [ "$UNINSTALL" = 1 ]; then
      if [ $old_link = 1 ] || [ $is_copy = 1 ]; then
        if [ $is_copy = 1 ]; then backup_item "$dest"; fi
        CHANGES=$((CHANGES + 1))
        step "remove  $dest"
        if [ "$DRY_RUN" = 0 ]; then
          if [ $old_link = 1 ]; then rm -f -- "$dest"; else rm -rf -- "$dest"; fi || die "cannot remove $dest"
        fi
      fi
      continue
    fi
    if [ -n "$target" ] && [ $old_link = 0 ]; then
      warn "skip    $dest is a link to $target, not to this kit. Move it, then re-run."
      continue
    fi
    if [ -z "$target" ] && [ $is_copy = 0 ] && [ -e "$dest" ]; then
      warn "skip    $dest exists and is not an Agent-kit copy. Move it, then re-run."
      continue
    fi
    if [ $is_copy = 1 ] && [ "$(dir_signature "$dest")" = "$(dir_signature "$src")" ]; then
      say "ok      $dest (copy up to date)"
      continue
    fi
    CHANGES=$((CHANGES + 1))
    if [ $old_link = 1 ]; then verb=relink; elif [ $is_copy = 1 ]; then verb=update; else verb='copy  '; fi
    step "$verb  $dest <- $src"
    if [ $is_copy = 1 ]; then backup_item "$dest"; fi
    [ "$DRY_RUN" = 1 ] && continue
    if [ $old_link = 1 ]; then rm -f -- "$dest" || die "cannot remove $dest"
    elif [ $is_copy = 1 ]; then rm -rf -- "$dest" || die "cannot remove $dest"
    fi
    mkdir -p "$dir" || die "cannot create $dir"
    cp -R "$src" "$dest" || die "cannot copy $src"
    printf 'Copied by Agent-kit install.sh from %s. Edit the kit, then re-run install.sh. Files added here are lost on the next run.\n' "$src" > "$dest/$COPY_MARKER" || die "cannot write $dest/$COPY_MARKER"
  done
  remove_stale_skills "$dir"
}

say "Agent-kit: $KIT"
for h in $HARNESS; do
  case $h in
    claude) rules="$HOME_DIR/.claude/CLAUDE.md"; skills="$HOME_DIR/.claude/skills"; mode="link" ;;
    gemini) rules="$HOME_DIR/.gemini/GEMINI.md"; skills="$HOME_DIR/.gemini/config/skills"; mode="copy" ;;
    codex) rules="$HOME_DIR/.codex/AGENTS.md"; skills="$HOME_DIR/.agents/skills"; mode="link" ;;
  esac
  say ""
  say "== $h =="
  body="$WORK/body-$h"
  if [ "$UNINSTALL" = 1 ]; then : > "$body"
  elif [ $h = claude ]; then claude_body "$body"
  else make_rules_text "$body"
  fi
  set_managed_block "$rules" "$body"
  if [ $mode = copy ]; then set_skill_copies "$skills"; else set_skill_links "$skills"; fi
  if [ $h = codex ] && [ "$UNINSTALL" = 0 ] && [ "$DRY_RUN" = 0 ] && [ -f "$rules" ]; then
    size=$(wc -c < "$rules" | tr -d ' ')
    if [ "$size" -gt 24576 ]; then
      kib=$(awk -v s="$size" 'BEGIN { printf "%.1f", s / 1024 }')
      warn "$rules is $kib KiB. Codex reads 32 KiB in total, project AGENTS.md included. Trim it."
    fi
  fi
done

say ""
if [ $CHANGES -eq 0 ]; then say 'Done. Nothing to change.'
elif [ "$DRY_RUN" = 1 ]; then say "Dry run: $CHANGES change(s) would be made."
else
  say "Done: $CHANGES change(s)."
  if [ -d "$BACKUP_DIR" ]; then say "Backups: $BACKUP_DIR"; fi
fi
exit 0
