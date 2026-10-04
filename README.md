# Digitakt II perform mods

Two [elekloader](https://github.com/irpina/elekloader) mods for PERFORM KIT
mode on the Digitakt II, OS 1.17. Use either one, or both together.

| mod | what it does |
|---|---|
| [perform-direct](perform-direct) | [PRESET] alone toggles PERFORM KIT, quicker to reach while playing live; [FUNC] + [PRESET] opens the PRESET/KIT menu |
| [perform-levels](perform-levels) | the track levels you leave PERFORM KIT mode with stay; every other parameter goes back to the pattern's kit, as stock |

On a unit (Digitakt II, OS 1.17): perform-levels works, and perform-direct's
key swap works (an earlier version, which also had an on/off row in
PERSONALIZE). The two together have been linted and built, not yet run on a unit.

## PERFORM KIT mode, stock

From the Digitakt II manual (OS 1.17, 10.10): in PERFORM KIT mode, changes
to the kit are not auto-saved, and kits are not reloaded when you change
patterns, so your tweaks carry over. [FUNC] + [PRESET] toggles the mode.
When you leave it, the pattern's own kit loads again and every tweak is
gone, track levels included.

## Install

You need elekloader (the app, the web page, or the command line) and the
stock OS file, `Digitakt_II_OS1.17.syx`, from Elektron. Download the
`.elemod` files from this repository's
[latest release](https://github.com/toonst/digitakt2-perform/releases/latest):
`perform-direct-*.elemod`, `perform-levels-*.elemod`, or both.

- Every mod needs elekloader's Digitakt II core. Until an elekloader release
  includes it, the release here carries it too: `core-1.0.elemod`. Add it
  with the mods.
- In elekloader, add the stock file and the `.elemod` files, then build.
- On the command line:

```bash
python -m elekloader.patch --stock Digitakt_II_OS1.17.syx \
    --mod core-1.0.elemod \
    --mod perform-direct-1.0.elemod \
    --mod perform-levels-1.0.elemod \
    --out perform.syx --version PB10
```

It prints `verified: ...` and `WROTE perform.syx`. Send `perform.syx` to the
unit with Elektron Transfer. To go back, send the stock OS file the same way.

## How they work

**perform-direct** (`perform.c`) handles core's `ev_key` event. For
[PRESET]'s key events (key 7) it flips the "[FUNC] held" flag (bit 2 of the
event's flags), so each combination does what the other one did.

**perform-levels** (`levels.s`, `levels.c`) has one site of its own:
- **The stock toggle** is 0x40064aec. Turned on, it copies the pattern's
  kit into a spare kit, slot 0x80 (0x40035e12), and plays that one.
  Turned off, it selects the pattern's kit again (0x40036cba).
- **The hook.** The off path starts at 0x40064ba6 with
  `move.l $98(a2),-(sp) ; jsr (a3)`. The site replaces those two
  instructions with a `jsr` to `pl_off`, which does their work and calls
  `pl_keep(kits, d2)`.
- **The copy.** `pl_keep` copies the 16 track-level words (kit + 0x14) from
  slot 0x80 into the pattern's kit. If any changed, it calls the kit
  collection's +0x5c(kits, slot, 0), as the firmware does after its own kit
  copies. The select that follows then loads those levels.

The levels go to the pattern that is active when you leave PERFORM KIT mode.
Only the 16 track levels are kept: pattern volume, send FX and everything
else go back.

**Checked in digikit's emulator** (perform-levels, 4 Oct 2026): a cold boot
passes every stage, as stock does. With PERFORM KIT on, the perform kit was
written directly (the emulator applies no encoder turn to a kit), then
PERFORM KIT was turned off:
- **Stock:** the pattern's kit kept its levels.
- **With the mod:** the pattern's kit took the perform kit's levels, and
  only those.

## Build

You need an elekloader checkout that has `mods/core-dt2`, and m68k binutils
and gcc (Homebrew's `m68k-elf-*` work).

```bash
ELEKLOADER=~/code/elekloader ./build.sh Digitakt_II_OS1.17.syx
```

This writes `dist/core-1.0.elemod`, `dist/perform-direct-1.0.elemod` and
`dist/perform-levels-1.0.elemod`, lints the three together, and prints
their sha256.

No firmware goes in this repository. The `.elemod` files hold the mods'
code and refer to stock bytes by position; elekloader fills those in from
each user's own stock file. They are attached to releases, never committed.

## Release

1. Bump `version` in the `mod.json` of each mod that changed.
2. Run `./build.sh`, then build a firmware with all three files and check
   it on a unit.
3. Tag `vX.Y`, then attach the files in `dist/` to a GitHub release:
   `gh release create vX.Y dist/*.elemod`.
4. For elekloader's mod shop, add one item per file to elekloader's
   `web/catalog.json` (`repo`, `tag`, `file`, `device: "digitakt-mk2"`,
   `sha256`; the core with `"kind": "core"`) in a pull request.

A later OS version (1.18, ...) means finding every address again. It goes
under `ports` in each `mod.json` (elekloader's docs/ADAPTING.md, 3.10).

## Licence

GPL-2.0-or-later ([LICENSE](LICENSE)), as elekloader. Both mods started as
examples in elekloader.
