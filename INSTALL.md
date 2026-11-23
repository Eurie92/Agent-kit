# Installing Agent-kit (for AI agents)

If a user asks you to install, set up or update Agent-kit, do this.

1. **Get the kit.**
   - If `~/Desktop/Agent-kit` does not exist, clone it there:
     ```
     git clone https://github.com/Eurie92/Agent-kit ~/Desktop/Agent-kit
     ```
     On Windows, use `"$HOME\Desktop\Agent-kit"`. If `~/Desktop` does not exist (for example, OneDrive moved it), create the folder anyway: the rules and skills expect this exact path.
   - If the folder exists but is not this repo, stop and ask the user.
2. **Run setup.** Read `~/Desktop/Agent-kit/skills/setup/SKILL.md` and follow it step by step. It interviews the user, reads their existing config, writes their personal settings into `local/` and runs the installer.
3. **Leave the shared files alone.** Do not change `rules/GLOBAL.md`, `skills/` or `templates/` during setup. Personal choices go in `local/`.

**Updating later.** Run `git -C ~/Desktop/Agent-kit pull`, then re-run the installer. Run setup again only to change the user's choices.
