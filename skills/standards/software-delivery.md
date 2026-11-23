# Software delivery

## When it applies
Every project: specs, tests, commits, releases, decisions, docs.

## Standards
- **Gherkin (Given/When/Then)**: write acceptance criteria as Given <context>, When <action>, Then <outcome>. Why: testable, readable by non-coders. Source: https://cucumber.io/docs/gherkin/reference/
- **Red-green regression test for bugs**: reproduce with a failing test before fixing. Why: proves the fix and stops the bug coming back. Source: https://martinfowler.com/bliki/TestDrivenDevelopment.html
- **Conventional Commits 1.0**: `type(scope): subject` (feat, fix, docs, chore, refactor, test). Why: readable history, automatable changelogs. Source: https://www.conventionalcommits.org/en/v1.0.0/
- **Semantic Versioning 2.0**: MAJOR.MINOR.PATCH. Why: users know what an update can break. Source: https://semver.org/
- **Keep a Changelog 1.1**: Added / Changed / Fixed / Removed sections per version. Why: humans read changelogs. Source: https://keepachangelog.com/en/1.1.0/
- **Architecture Decision Records**: date, context, decision, consequences, who decided. Why: future you knows why. Source: https://adr.github.io/
- **Diátaxis**: separate tutorials, how-to guides, reference and explanation in docs. Why: each reader finds what they need. Source: https://diataxis.fr/
- **AGENTS.md**: one plain markdown file of project instructions for coding agents. Why: every harness reads it. Source: https://agents.md/
- **Agent Skills (SKILL.md)**: folder with SKILL.md (name + description frontmatter), loaded on demand. Why: portable across harnesses. Source: https://code.claude.com/docs/en/skills

## Rules worth keeping
- (none yet)
