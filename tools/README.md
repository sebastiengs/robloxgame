# tools/

These are **not** part of the running game. Rojo does not sync this folder — only `src/`
is mapped in `default.project.json`.

- `Build*.lua` — one-off scripts that build the maps and gun models. Run them by pasting
  into the Studio **command bar** while play mode is stopped.
- `Install*.lua` — one-off installers that place scripts and objects into the place.
- `GunClient.client.lua` — the shared gun LocalScript. It lives *inside each Tool* in
  `ReplicatedStorage.GunTemplates`, and Tools aren't mapped by Rojo, so it can't be synced
  from `src/`. Edit it here, then push it into the guns with `InstallNewGuns.lua`.
