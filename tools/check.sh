#!/usr/bin/env bash
# Repo checks for contributors and CI. Run from anywhere: bash tools/check.sh
# Checks: skill front matter, nothing tracked under local/, ASCII-only PowerShell files,
# shell syntax, relative links in Markdown files, and routing JSON (needs node).
cd "$(dirname "$0")/.." || exit 1
FAILS=0
fail() { echo "FAIL $*"; FAILS=$((FAILS + 1)); }

# 1. Every skill folder has SKILL.md with front matter: name (= folder name) and description.
for d in skills/*/; do
  name=$(basename "$d")
  f="${d%/}/SKILL.md"
  if [ ! -f "$f" ]; then fail "$d has no SKILL.md"; continue; fi
  head -1 "$f" | grep -qx -- '---' || { fail "$f must start with a --- front matter line"; continue; }
  fm=$(awk 'NR==1{next} /^---$/{exit} {print}' "$f")
  printf '%s\n' "$fm" | grep -qx "name: $name" || fail "$f front matter needs 'name: $name'"
  printf '%s\n' "$fm" | grep -q '^description: .\{20,\}' || fail "$f front matter needs a 'description:' (20+ characters)"
done

# 2. Personal settings never get committed.
if git ls-files --error-unmatch local >/dev/null 2>&1 || [ -n "$(git ls-files local)" ]; then
  fail "files under local/ are tracked; they hold personal settings and must stay git-ignored"
fi

# 3. Windows PowerShell 5.1 reads files without a BOM as ANSI, so keep .ps1 files ASCII.
for f in $(git ls-files '*.ps1'); do
  if LC_ALL=C grep -n '[^[:print:][:space:]]' "$f" >/dev/null; then
    fail "$f has non-ASCII characters: $(LC_ALL=C grep -n '[^[:print:][:space:]]' "$f" | head -3 | cut -c1-80)"
  fi
done

# 4. Shell scripts parse.
for f in $(git ls-files '*.sh'); do
  bash -n "$f" 2>/dev/null || fail "$f has a bash syntax error (run: bash -n $f)"
done

# 5. Relative Markdown links point to files that exist (code blocks are skipped).
for f in $(git ls-files '*.md'); do
  dir=$(dirname "$f")
  awk '/^```/{c=!c; next} !c' "$f" | grep -o '\]([^)]*)' | sed 's/^](//; s/)$//; s/ .*//' |
  while IFS= read -r link; do
    case "$link" in ''|http://*|https://*|mailto:*|\#*) continue ;; esac
    target=${link%%#*}
    [ -e "$dir/$target" ] || echo "FAIL $f links to missing $link"
  done
done > "${TMPDIR:-/tmp}/agent-kit-links.$$"
if [ -s "${TMPDIR:-/tmp}/agent-kit-links.$$" ]; then
  cat "${TMPDIR:-/tmp}/agent-kit-links.$$"
  FAILS=$((FAILS + $(wc -l < "${TMPDIR:-/tmp}/agent-kit-links.$$")))
fi
rm -f "${TMPDIR:-/tmp}/agent-kit-links.$$"

# 6. Routing files match schemas/routing.schema.json: the committed example, and local/routing.json when present.
if command -v node >/dev/null 2>&1; then
  node tools/validate-routing.mjs || fail "routing file(s) do not match schemas/routing.schema.json"
  node tools/test-validate-routing.mjs >/dev/null || fail "tools/test-validate-routing.mjs failed (run it to see why)"
else
  echo "note: node not found, skipping routing checks"
fi

if [ "$FAILS" -eq 0 ]; then echo "check.sh: all checks passed"; exit 0; fi
echo "check.sh: $FAILS problem(s)"
exit 1
