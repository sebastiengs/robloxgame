# Prompt to paste into Claude Code on the laptop that has the game code

You can read this file on GitHub without cloning anything:
https://github.com/sebastiengs/robloxgame/blob/claude/games-github-setup-utygwe/docs/HANDOFF_PROMPT.md

## Before you paste it

Install these on the laptop first — they need a real installer and probably an admin
password, so an assistant can't do them for you:

- **Git** — https://git-scm.com/downloads
- **Rokit** — https://github.com/rojo-rbx/rokit#installation
- **VS Code** (or any editor) — https://code.visualstudio.com
- **The Rojo plugin for Studio** — in Studio: **Toolbox → Plugins**, search "Rojo", install

It's your dad's laptop, so ask him before installing things on it.

## The prompt

Open a terminal, `cd` to where you keep the game project, start Claude Code, and paste:

```
This repo is github.com/sebastiengs/robloxgame, branch
claude/games-github-setup-utygwe. Read docs/MOVING_YOUR_CODE.md and do Part 1
for me. My game code is on this laptop and/or in the Roblox place currently
open in Studio. Work out which, get it into src/server, src/client and
src/shared with the right file name endings, delete the placeholder Hello and
Config files, then stop before committing and tell me what to check in Studio.
```

It stops before committing on purpose. You want to connect Rojo and press Play while
mistakes are still easy to fix, rather than after everything is pushed.

## Then do these yourself

1. Start the sync: `rojo serve` in a terminal, left running.
2. In Studio: **Plugins → Rojo → Connect**.
3. Check the Explorer panel — your scripts should be in the right places.
4. Press **Play** and confirm the game still behaves the way it did before.

If Studio warns that it will overwrite existing scripts, that's expected the first time.
Rojo is replacing what's in Studio with what's in your files, which is the whole point:
the files on disk are the real version now.

## Then commit and push

Once the game plays correctly, tell Claude Code:

```
That all worked. Commit it and push to claude/games-github-setup-utygwe.
```

You'll need to be signed in to GitHub for the push to go through. Do that in the browser,
or paste an access token — don't type your GitHub password into the chat.

## If something looks wrong

Don't push. Say what you saw instead:

```
Rojo connected but <describe what's wrong — scripts missing, in the wrong
place, game errors on Play>. Don't commit anything yet.
```

Nothing is lost at that point. Your original scripts are still in the Roblox place, and
nothing has been pushed to GitHub.
