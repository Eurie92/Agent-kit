#!/usr/bin/env bash
# Variables such as CODE are read inside the check strings, which run through eval.
# shellcheck disable=SC2034
# Tests for install.sh. Each case runs the installer against a copy of the kit and a fake home in a
# temp folder, so the real home and the real kit are never touched.
#
# Usage: bash install/test-install.sh
#   INSTALL_BASH=/bin/bash bash install/test-install.sh   (run the installer with another bash, e.g. 3.2 on macOS)
# Exit code 0 = all checks passed.

REPO=$(cd "$(dirname "$0")/.." && pwd -P) || exit 1
INSTALL_BASH=${INSTALL_BASH:-bash}
case $(uname -s) in
  # Git Bash on Windows (for local runs only): emulate symlinks without admin rights.
  MINGW*|MSYS*|CYGWIN*) export MSYS=winsymlinks:sys CYGWIN=winsymlinks:sys ;;
esac
T=$(mktemp -d "${TMPDIR:-/tmp}/agent-kit-test.XXXXXX") && T=$(cd "$T" && pwd -P) || exit 1
trap 'rm -rf "$T"' EXIT

PASS=0
FAIL=0
OUT=
CODE=

check() {
  # check NAME CONDITION: CONDITION is evaluated as shell code.
  if eval "$2"; then
    PASS=$((PASS + 1)); echo "PASS $1"
  else
    FAIL=$((FAIL + 1)); echo "FAIL $1"
    printf '%s\n' "$OUT" | sed 's/^/    | /'
  fi
}

run() {
  # run KIT HOME [FLAGS...]: runs the installer, sets OUT (stdout + stderr) and CODE.
  local kit=$1 home=$2
  shift 2
  OUT=$(HOME="$home" T3CODE_HOME="${TEST_T3_HOME:-}" "$INSTALL_BASH" "$kit/install/install.sh" "$@" 2>&1)
  CODE=$?
}

make_kit() {
  # make_kit DIR [nolocal]: copies install/, rules/, skills/ and templates/, plus test local/ files.
  mkdir -p "$1" && cp -R "$REPO/install" "$REPO/rules" "$REPO/skills" "$REPO/templates" "$1/" || exit 1
  if [ "$2" != nolocal ]; then
    mkdir -p "$1/local"
    printf '# Model routing (test)\n\n- Lead: test model\n' > "$1/local/MODELS.md"
    printf '# Personal preferences (test)\n\n- Plain and short.\n' > "$1/local/PREFS.md"
  fi
}

hasf() { printf '%s\n' "$OUT" | grep -qF -- "$1"; }
count() { printf '%s\n' "$OUT" | grep -c -- "^$1"; }
empty_dir() { [ -d "$1" ] && [ -z "$(ls -A "$1")" ]; }
contains() { grep -qF -- "$2" "$1"; }
entries() { ls -A "$1" 2>/dev/null | wc -l | tr -d ' '; }

all_linked() {
  local s
  for s in $SKILL_NAMES; do
    [ -L "$1/$s" ] && [ "$(readlink "$1/$s")" = "$K/skills/$s" ] || return 1
  done
}

all_copied() {
  local s
  for s in $SKILL_NAMES; do
    [ ! -L "$1/$s" ] && [ -f "$1/$s/SKILL.md" ] && [ -f "$1/$s/.agent-kit-copy" ] || return 1
  done
}

echo "Installer bash: $("$INSTALL_BASH" -c 'echo $BASH_VERSION') on $(uname -s)"

# --- No local/ files: exit 1, nothing changed (spec case 1)
K1=$T/kit-nolocal
make_kit "$K1" nolocal
H=$T/home-nolocal
mkdir -p "$H"
run "$K1" "$H"
check 'no local: exit 1' '[ "$CODE" = 1 ]'
check 'no local: names both files' 'hasf "Missing: local/MODELS.md, local/PREFS.md. Nothing was changed."'
check 'no local: home untouched' 'empty_dir "$H"'
mkdir -p "$K1/local"
echo x > "$K1/local/MODELS.md"
run "$K1" "$H"
check 'one local file missing: exit 1' '[ "$CODE" = 1 ] && hasf "Missing: local/PREFS.md. Nothing was changed."'
run "$K1" "$H" --uninstall
check 'uninstall works without local/' '[ "$CODE" = 0 ]'

# --- Main kit
K=$T/kit
make_kit "$K"
SKILL_NAMES=
for d in "$K"/skills/*/; do
  [ -f "$d/SKILL.md" ] && SKILL_NAMES="$SKILL_NAMES $(basename "$d")"
done
KIT_FILES=$(find "$K/skills" -type f | wc -l | tr -d ' ')
H=$T/home
mkdir -p "$H"
CL=$H/.claude/CLAUDE.md
G=$H/.gemini/GEMINI.md
C=$H/.codex/AGENTS.md
GS=$H/.gemini/config/skills

# --- Dry run on an empty home
run "$K" "$H" --dry-run
check 'dry run: exit 0' '[ "$CODE" = 0 ]'
check 'dry run: counts changes' 'hasf "Dry run: " && hasf "change(s) would be made."'
check 'dry run: home untouched' 'empty_dir "$H"'

# --- Install twice (spec case 2)
run "$K" "$H"
check 'install: exit 0' '[ "$CODE" = 0 ]'
check 'install: reports changes' 'hasf "Done: " && hasf "change(s)."'
run "$K" "$H"
check 'second run: Nothing to change' '[ "$CODE" = 0 ] && hasf "Done. Nothing to change."'
check 'claude: 3 imports, in order' '[ "$(grep "^@" "$CL" | tr "\n" " ")" = "@$K/rules/GLOBAL.md @$K/local/MODELS.md @$K/local/PREFS.md " ]'
check 'claude: one managed block' '[ "$(grep -c "agent-kit:start" "$CL")" = 1 ] && [ "$(grep -c "agent-kit:end" "$CL")" = 1 ]'
GLOBAL_HEAD=$(head -n 1 "$K/rules/GLOBAL.md")
for f in "$G" "$C"; do
  check "$(basename "$f"): has GLOBAL, MODELS and PREFS" 'contains "'"$f"'" "$GLOBAL_HEAD" && contains "'"$f"'" "# Model routing (test)" && contains "'"$f"'" "# Personal preferences (test)"'
done
check 'claude skills: links to the kit' 'all_linked "$H/.claude/skills"'
check 'codex skills: links to the kit' 'all_linked "$H/.agents/skills"'
check 'gemini skills: copies with a marker' 'all_copied "$GS"'
check 'skill content readable through the link' 'cmp -s "$H/.claude/skills/setup/SKILL.md" "$K/skills/setup/SKILL.md"'

# --- User text around the block, and a CRLF file, are kept
{ printf '# My top rule\n\n'; cat "$G"; printf '\n# My bottom rule\n'; } > "$T/tmp" && mv "$T/tmp" "$G"
awk '{ printf "%s\r\n", $0 }' "$C" > "$T/tmp" && mv "$T/tmp" "$C"
cp "$C" "$T/codex-before"
run "$K" "$H"
check 'user text + CRLF: Nothing to change' 'hasf "Done. Nothing to change."'
check 'gemini: first line is user text' '[ "$(head -n 1 "$G")" = "# My top rule" ]'
check 'gemini: last line is user text' '[ "$(tail -n 1 "$G")" = "# My bottom rule" ]'
check 'codex: CRLF file byte-identical' 'cmp -s "$C" "$T/codex-before"'

# --- A dangling Claude link and an old Gemini link to the kit are relinked
rm -f "$H/.claude/skills/audit"
ln -s "$T/gone" "$H/.claude/skills/audit"
rm -rf "$GS/ship"
ln -s "$K/skills/ship" "$GS/ship"
run "$K" "$H"
check 'dangling claude link: relinked' 'hasf "relink  $H/.claude/skills/audit -> $K/skills/audit" && [ "$(readlink "$H/.claude/skills/audit")" = "$K/skills/audit" ]'
check 'old gemini link: replaced by a copy' 'hasf "relink  $GS/ship <- $K/skills/ship" && [ ! -L "$GS/ship" ] && [ -f "$GS/ship/.agent-kit-copy" ]'
check 'kit ship skill still intact' '[ -f "$K/skills/ship/SKILL.md" ]'

# --- A new kit skill is linked and copied, an edited one is updated, a removed one is pruned
mkdir "$K/skills/zz-temp"
printf -- '---\nname: zz-temp\ndescription: test\n---\n' > "$K/skills/zz-temp/SKILL.md"
run "$K" "$H"
check 'new skill: 2 links and 1 copy' '[ "$(count "link    ")" = 2 ] && [ "$(count "copy    ")" = 1 ]'
echo 'edited line' >> "$K/skills/zz-temp/SKILL.md"
run "$K" "$H"
check 'edited skill: gemini copy updated' 'hasf "update  $GS/zz-temp <- $K/skills/zz-temp" && contains "$GS/zz-temp/SKILL.md" "edited line"'
check 'edited skill: old copy backed up' 'BK=$(printf "%s\n" "$OUT" | sed -n "s/^Backups: //p") && [ -f "$BK/.gemini/config/skills/zz-temp/SKILL.md" ] && ! contains "$BK/.gemini/config/skills/zz-temp/SKILL.md" "edited line"'
rm -rf "$K/skills/zz-temp"
run "$K" "$H"
check 'removed skill: 2 unlinks and 1 remove' '[ "$(count "unlink  ")" = 2 ] && [ "$(count "remove  ")" = 1 ]'
check 'removed skill: gone from all 3 folders' '[ ! -e "$H/.claude/skills/zz-temp" ] && [ ! -L "$H/.claude/skills/zz-temp" ] && [ ! -e "$H/.agents/skills/zz-temp" ] && [ ! -e "$GS/zz-temp" ]'

# --- Broken markers: warn and leave the file alone
cp "$CL" "$T/claude-before"
printf '<!-- agent-kit:start stray -->\n' >> "$CL"
cp "$CL" "$T/claude-broken"
run "$K" "$H" --harness claude
check 'broken markers: warning' 'hasf "skip    $CL has broken or duplicate agent-kit markers"'
check 'broken markers: file unchanged' 'cmp -s "$CL" "$T/claude-broken"'
cp "$T/claude-before" "$CL"

# --- Uninstall removes only what the installer made
run "$K" "$H" --uninstall
check 'uninstall: exit 0' '[ "$CODE" = 0 ]'
check 'uninstall: no links or copies left' '[ "$(entries "$H/.claude/skills")" = 0 ] && [ "$(entries "$H/.agents/skills")" = 0 ] && [ "$(entries "$GS")" = 0 ]'
check 'uninstall: block-only files deleted' '[ ! -e "$CL" ] && [ ! -e "$C" ]'
check 'uninstall: gemini user text kept' '[ "$(cat "$G")" = "$(printf "# My top rule\n\n# My bottom rule")" ]'
check 'uninstall: kit skills intact' '[ "$(find "$K/skills" -type f | wc -l | tr -d " ")" = "$KIT_FILES" ]'
run "$K" "$H" --uninstall
check 'uninstall again: Nothing to change' 'hasf "Done. Nothing to change."'

# --- An old block is replaced in place; outside text and CRLF are kept (spec case 6)
H6=$T/home-old-block
mkdir -p "$H6/.claude"
printf '# My top rule\r\n\r\n<!-- agent-kit:start (managed by Agent-kit install.ps1; edits inside are overwritten) -->\r\n@~/Desktop/Agent-kit/rules/GLOBAL.md\r\n@~/Desktop/Agent-kit/rules/MODELS.md\r\n<!-- agent-kit:end -->\r\n\r\n# My bottom rule\r\n' > "$H6/.claude/CLAUDE.md"
printf '# My top rule\r\n\r\n%s\r\n@%s/rules/GLOBAL.md\r\n@%s/local/MODELS.md\r\n@%s/local/PREFS.md\r\n%s\r\n\r\n# My bottom rule\r\n' \
  '<!-- agent-kit:start (managed by Agent-kit install.sh; edits inside are overwritten) -->' "$K" "$K" "$K" '<!-- agent-kit:end -->' > "$T/expected-old-block"
run "$K" "$H6" --harness claude
check 'old block: exit 0' '[ "$CODE" = 0 ]'
check 'old block: replaced in place, CRLF and outside text kept (exact bytes)' 'cmp -s "$H6/.claude/CLAUDE.md" "$T/expected-old-block"'
check 'old block: only claude touched' '[ ! -e "$H6/.gemini" ] && [ ! -e "$H6/.codex" ] && [ ! -e "$H6/.agents" ]'

# --- Harness list
HH=$T/home-harness
mkdir -p "$HH"
run "$K" "$HH" --harness claude,gemini
check 'harness list: exit 0' '[ "$CODE" = 0 ]'
check 'harness list: claude and gemini only' '[ -f "$HH/.claude/CLAUDE.md" ] && [ -f "$HH/.gemini/GEMINI.md" ] && [ ! -e "$HH/.codex" ] && [ ! -e "$HH/.agents" ]'
run "$K" "$HH" --harness 'claude, Gemini'
check 'harness list with space and capitals: Nothing to change' '[ "$CODE" = 0 ] && hasf "Done. Nothing to change."'
HB=$T/home-bad
mkdir -p "$HB"
run "$K" "$HB" --harness claude,cursor
check 'bad harness: exit 1 naming it' '[ "$CODE" = 1 ] && hasf "Unknown --harness value: cursor."'
check 'bad harness: home untouched' 'empty_dir "$HB"'
run "$K" "$HB" --bogus
check 'unknown option: exit 1' '[ "$CODE" = 1 ] && hasf "Unknown option: --bogus" && empty_dir "$HB"'

# --- Foreign links and folders are skipped and left alone
HF=$T/home-foreign
mkdir -p "$HF/.claude/skills/audit" "$HF/.agents/skills" "$T/elsewhere/setup"
echo mine > "$HF/.claude/skills/audit/SKILL.md"
ln -s "$T/elsewhere/setup" "$HF/.agents/skills/setup"
run "$K" "$HF" --harness claude,codex
check 'foreign folder: skipped and kept' 'hasf "skip    $HF/.claude/skills/audit exists and is not an Agent-kit link" && contains "$HF/.claude/skills/audit/SKILL.md" mine'
check 'foreign link: skipped and kept' 'hasf "skip    $HF/.agents/skills/setup is a link to $T/elsewhere/setup, not to this kit" && [ "$(readlink "$HF/.agents/skills/setup")" = "$T/elsewhere/setup" ]'
run "$K" "$HF" --harness claude,codex --uninstall
check 'foreign items survive uninstall' '[ -f "$HF/.claude/skills/audit/SKILL.md" ] && [ -L "$HF/.agents/skills/setup" ] && [ -d "$T/elsewhere/setup" ]'

# --- Kit inside the home folder: imports use ~
HK=$T/home-kit
make_kit "$HK/Desktop/Agent-kit"
run "$HK/Desktop/Agent-kit" "$HK" --harness claude
check 'kit under home: imports start with ~' 'grep -qx "@~/Desktop/Agent-kit/rules/GLOBAL.md" "$HK/.claude/CLAUDE.md"'

# --- Kit path with a space: Claude gets a copy of the rules
KS="$T/kit with space"
make_kit "$KS"
HS=$T/home-space
mkdir -p "$HS"
run "$KS" "$HS" --harness claude
check 'space in kit path: warning' 'hasf "The kit path has a space"'
check 'space in kit path: rules copied, no imports' 'contains "$HS/.claude/CLAUDE.md" "# Personal preferences (test)" && ! grep -q "^@" "$HS/.claude/CLAUDE.md"'
check 'space in kit path: skills still linked' '[ "$(readlink "$HS/.claude/skills/setup")" = "$KS/skills/setup" ]'

# --- Codex size warning
KB=$T/kit-big
make_kit "$KB"
awk 'BEGIN { for (i = 0; i < 400; i++) print "- Filler line that makes the rules file big enough to trigger the warning." }' >> "$KB/local/PREFS.md"
HZ=$T/home-big
mkdir -p "$HZ"
run "$KB" "$HZ" --harness codex
check 'big codex file: size warning' 'hasf "Codex reads 32 KiB in total"'

# --- Bot templates (T3CODE_HOME)
HT3=$T/home-t3
T3D=$T/t3-existing
mkdir -p "$HT3" "$T3D/bots/other-bot"
echo keep > "$T3D/bots/other-bot/SOUL.md"
TEST_T3_HOME=$T3D
run "$K" "$HT3" --harness claude --dry-run
check 't3 dry run: exit 0 and writes nothing' '[ "$CODE" = 0 ] && hasf "Dry run: " && [ ! -e "$T3D/bots/templates" ]'
run "$K" "$HT3" --harness claude
check 't3 install: exit 0' '[ "$CODE" = 0 ]'
for b in saver reviewer shipper client-update; do
  check "t3 install: kit-$b/template.json byte-identical" 'cmp -s "$T3D/bots/templates/kit-'"$b"'/template.json" "$K/templates/bots/starters/'"$b"'/template.json"'
done
run "$K" "$HT3" --harness claude
check 't3 second run: Nothing to change' '[ "$CODE" = 0 ] && hasf "Done. Nothing to change."'
printf '{"bad":true}\n' > "$T3D/bots/templates/kit-saver/template.json"
run "$K" "$HT3" --harness claude
check 't3 overwrite: updated and backed up' '[ "$CODE" = 0 ] && hasf "update  $T3D/bots/templates/kit-saver/template.json" && cmp -s "$T3D/bots/templates/kit-saver/template.json" "$K/templates/bots/starters/saver/template.json"'
run "$K" "$HT3" --harness claude --uninstall
check 't3 uninstall: removes kit-* and empty templates dir' '[ "$CODE" = 0 ] && [ ! -e "$T3D/bots/templates" ]'
check 't3 uninstall: leaves unrelated bots/ folder alone' '[ -f "$T3D/bots/other-bot/SOUL.md" ] && contains "$T3D/bots/other-bot/SOUL.md" keep'

HT3M=$T/home-t3-missing
T3M=$T/t3-missing
mkdir -p "$HT3M"
TEST_T3_HOME=$T3M
run "$K" "$HT3M" --harness claude
check 't3 missing home: exit 0, skipped and creates nothing' '[ "$CODE" = 0 ] && hasf "bot templates skipped" && [ ! -e "$T3M" ]'
TEST_T3_HOME=

echo
echo "PASS: $PASS  FAIL: $FAIL"
[ "$FAIL" = 0 ]
