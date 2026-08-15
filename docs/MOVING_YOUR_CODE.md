# Getting your game onto GitHub, and onto every laptop

Your game code is currently on one laptop. This guide has two parts:

- **Part 1** — run this **once**, on the laptop that has your game code on it.
- **Part 2** — run this on **every other laptop** you want to work from.

Take Part 1 slowly. Part 2 takes about five minutes per laptop after that.

---

## Before you start: install the tools

On **each** laptop you'll need:

1. **Git** — https://git-scm.com/downloads
2. **Roblox Studio** — you already have this
3. **Rokit** — installs the right version of Rojo automatically:
   https://github.com/rojo-rbx/rokit#installation
4. **The Rojo plugin for Studio** — in Studio: **Toolbox → Plugins**, search "Rojo", install it.
   (Or run `rojo plugin install` in a terminal.)
5. A code editor — **VS Code** is the usual pick: https://code.visualstudio.com

---

## Part 1 — on the laptop that has your game code

### Step 1: Find out how the code is stored right now

You mentioned Claude Code has been connecting to Roblox Studio on that laptop. There are two
likely situations, and the first thing to do is work out which one you're in.

Open the folder where you've been working with Claude Code and look for these:

- **A `default.project.json` file** → you're already using Rojo. Great, go to Step 2.
- **A folder of `.lua` or `.luau` files** but no `default.project.json` → the code is on disk
  but not yet wired to Studio. Go to Step 2; you'll use the `default.project.json` from this
  repo.
- **Nothing on disk — everything lives inside Studio** → do Step 1b first.

### Step 1b: Only if your scripts live inside Studio and not on disk

You need to get them out into files. For a small game, copying and pasting is genuinely the
fastest route and you can't mess it up:

1. In Studio, open the Explorer panel (**View → Explorer**).
2. For each script, look at where it sits:
   - In `ServerScriptService` → it goes in `src/server/`, named `TheName.server.luau`
   - In `StarterPlayer > StarterPlayerScripts` → `src/client/`, named `TheName.client.luau`
   - In `ReplicatedStorage` → `src/shared/`, named `TheName.luau`
3. Open each script, select all, copy, and paste it into a new file with that name and path.

Do them one at a time and keep Studio open — nothing is deleted, you're only copying.

### Step 2: Get this repo onto that laptop

Open a terminal, `cd` to wherever you keep projects, and run:

```bash
git clone https://github.com/sebastiengs/robloxgame.git
cd robloxgame
git checkout claude/games-github-setup-utygwe
```

### Step 3: Copy your game code in

Copy your actual scripts into `src/server/`, `src/client/`, and `src/shared/` following the
table in the main [README](../README.md).

If your existing project already had its own `src/` layout and a `default.project.json`,
just copy the whole thing over the top of these files — your version wins. Delete the three
placeholder `Hello` / `Config` files once your real code is in.

### Step 4: Check it actually works before committing

```bash
rokit install
rojo serve
```

Leave that running. In Studio, open your game, then **Plugins → Rojo → Connect**.

Look in the Explorer panel — your scripts should appear in the right places. Press Play and
make sure the game still behaves. **Don't skip this.** It's much easier to fix a wrong folder
now than after everything is pushed.

### Step 5: Push it up

```bash
git add -A
git commit -m "Add game code"
git push -u origin claude/games-github-setup-utygwe
```

Your code is now on GitHub. That's the backup, and that's the copy every other laptop reads from.

---

## Part 2 — on any other laptop

Install the tools listed at the top, then:

```bash
git clone https://github.com/sebastiengs/robloxgame.git
cd robloxgame
git checkout claude/games-github-setup-utygwe
rokit install
rojo serve
```

In Studio: open the place, **Plugins → Rojo → Connect**. You're working on the same game.

When you finish, push your changes:

```bash
git add -A
git commit -m "what you changed"
git push
```

And each time you sit down at a laptop, **pull first**:

```bash
git pull
```

---

## The one rule that keeps this from going wrong

**Pull before you start. Push before you stop.**

If you edit the same file on two laptops without pushing in between, git will ask you to
merge the two versions by hand. Not the end of the world, but annoying. The habit above
avoids it entirely.

---

## Things that go wrong, and what they mean

**"rojo: command not found"** — Rokit isn't installed, or you skipped `rokit install`, or
your terminal needs restarting after installing Rokit.

**Studio won't connect to Rojo** — `rojo serve` has to be running in a terminal *at the same
time*, from inside the project folder. If it isn't running there's nothing to connect to.

**Connected, but the scripts don't show up in Studio** — the folder names in
`default.project.json` don't match your actual folders. Check the paths in that file against
what's really in `src/`.

**Studio warns "this will overwrite existing scripts"** — expected the first time. Rojo is
replacing what's in Studio with what's in your files. That's the point: **the files on disk
are the real version now**, and Studio is just a viewer for them.

**Push rejected, "fetch first"** — someone (or you, on another laptop) pushed since you last
pulled. Run `git pull`, then push again.

---

## A note on your map and models

Everything above covers *code*. If you've built a map by dragging parts around in Studio,
that's stored in the Roblox place file, not in these files, so it won't travel through GitHub
on its own.

Easiest approach: keep opening the same Roblox place on both laptops (it's in your Roblox
account, so it follows you), and let Rojo supply the scripts on top of it. That gives you the
map from the cloud and the code from GitHub.
