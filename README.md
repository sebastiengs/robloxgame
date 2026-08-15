# robloxgame

A Roblox game whose code lives on GitHub, so it can be worked on from any laptop.

**New here? Start with [`docs/MOVING_YOUR_CODE.md`](docs/MOVING_YOUR_CODE.md)** — it walks
through getting the game code that's currently on one laptop into this repo, then getting
it back down on any other laptop.

**Sitting at the laptop that has the code, with Claude Code open?** Use
[`docs/HANDOFF_PROMPT.md`](docs/HANDOFF_PROMPT.md) — a prompt to paste that does most of
Part 1 for you.

## How this works

Roblox Studio normally keeps your game in Roblox's cloud, tied to whatever machine you
happen to be on. This repo uses a tool called **Rojo** instead: your scripts live as plain
text files on disk, git tracks them, and Rojo streams them live into Studio while you work.
Save a file in your editor → it updates in Studio a second later.

That's what makes "work from anywhere" possible. Any laptop that can `git clone` this repo
gets the whole game.

## Folder layout

| Folder | Becomes this in Studio | What goes here |
|---|---|---|
| `src/server/` | `ServerScriptService` | Server code. Players can't see or tamper with it. |
| `src/client/` | `StarterPlayerScripts` | Client code, runs on each player's device. |
| `src/shared/` | `ReplicatedStorage.Shared` | ModuleScripts both sides can `require()`. |

File name endings matter:

- `Thing.server.luau` → a **Script** (server)
- `Thing.client.luau` → a **LocalScript** (client)
- `Thing.luau` → a **ModuleScript**
- A folder named `Thing/` with an `init.luau` inside → a ModuleScript named `Thing`

`default.project.json` is the map from these folders to Studio. Edit it if you want to add
new locations.

## Daily workflow, once you're set up

```bash
git pull                 # get any changes made from another laptop
rojo serve               # leave this running
```

Then in Studio: **Plugins → Rojo → Connect**. Edit files in your editor; Studio updates live.

When you're done for the day:

```bash
git add -A
git commit -m "describe what you changed"
git push
```

That last step is what makes the work show up on your other laptop. **If you don't push, the
other laptop can't see it.**

## What is *not* in this repo

Git tracks the code, not the built place file. `.rbxl` / `.rbxlx` files are in `.gitignore`
on purpose — they're binary blobs that git can't merge, and they'd cause conflicts constantly.

Things you build by dragging parts around in Studio's 3D viewport (the map, models, terrain)
also aren't code, so they don't live here by default. Options for those:

- Keep the map in the Roblox cloud place and let Rojo supply only the scripts. Simplest, and
  fine for most projects.
- Export models you care about as `.rbxmx` and commit them under an `assets/` folder.
- Build the map in code instead.

## Setup on a new laptop

See [`docs/MOVING_YOUR_CODE.md`](docs/MOVING_YOUR_CODE.md), section **"Part 2"**.
